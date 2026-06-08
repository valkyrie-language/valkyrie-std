# Valkyrie 多阶段编程（MSP）系统：理念、设计与实现（修订版）

## 1. 引言

多阶段编程（Multi-Stage Programming, MSP）是一种元编程范式，它允许程序在编译期生成或变换代码，同时通过严格的阶段分离避免传统宏系统（如 C 预处理器）或模板元编程中常见的卫生性问题和组合性缺失。Valkyrie 编译器从零构建了一套完整的 MSP 体系，其核心引擎 `MetaStager` 位于编译管线中 Parse 与 Analyze 之间，负责对抽象语法树（AST）执行编译期变换，消除所有元代码节点（`<% ... %>`），最终生成纯粹的运行时（Stage 0）代码。本文详细阐述 Valkyrie MSP 的基本理念、详细设计及其参考实现，旨在为语言设计者、编译器开发者提供一套可借鉴的完整方案。

## 2. 基本理念

### 2.1 什么是多阶段编程

多阶段编程将程序的执行划分为不同的阶段（Stage）。Stage 0 为传统的运行时，Stage 1 为编译期执行的代码，Stage 2 为生成 Stage 1 代码的代码，依此类推。每个阶段可以生成或操作后续阶段的代码，但禁止反向依赖，从而形成严格的有向无环依赖图。

与 Lisp 宏或 C 预处理器不同，MSP 不操作文本，而是直接操作 AST 节点。这使得变换是**类型安全的**、**卫生的**（自动避免变量捕获）并且**可组合的**。Valkyrie 的设计汲取了 MetaOCaml、Scala LMS 和 Rust 声明宏的优点，同时通过自定义语法和延迟展开策略解决了世界年龄（World Age）问题，并完整支持任意深度的多阶段编程。

### 2.2 与模板元编程的本质区别

C++ 模板元编程是图灵完备的，但其根本问题在于：
- **字符串/标记拼贴**：大量实践依赖预处理器的 `##` 拼接，破坏卫生性。
- **不可组合**：模板实例化后产生的代码是无法作为 AST 再次被其他模板内省或生成的。SFINAE、特化等手段只能在“类型推导”层面组合，无法对生成代码的结构进行二次加工。
- **错误诊断困难**：模板展开错误通常指向展开后的代码，难以定位原始意图。

MSP 通过**显式的 AST 构造与操作**解决了这些问题。Valkyrie 中的 `<% ... %>` 块直接嵌入在 AST 中，编译器理解这些节点的语义，能够确保：
1. 所有 escape 的结果都是合法的 AST 子树，标识符不可拼接。
2. 变量绑定遵循词法作用域，且 Stage N 变量绝不会污染 Stage N-1 作用域。
3. 宏的输出仍然是完整的 AST，可继续被其他宏处理，甚至可包含新的宏定义，实现真正的可组合性与多阶段传递。

### 2.3 卫生性（Hygiene）

卫生性是指宏系统自动避免生成的代码意外捕获或改变外部变量的绑定。在 Valkyrie MSP 中，卫生性由以下机制保证：
- **所有 escape 生成的是 AST 节点，而非字符串**。例如 `let x = <% value %>;` 中，`<% value %>` 被求值为一个 `MetaValue`，然后转换为对应的字面量节点（整数、字符串等）或 AST 片段，绝不会出现 `value_<% i %>` 这类拼接标识符的情况。
- **作用域隔离**：每个 staging level 维护独立的 `Bindings` 字典。当宏体展开时，会在新的子层级中执行，其引入的变量（如循环变量）不会泄漏到外部。Stage N 的变量在 Stage N-1 完全不可见，反之亦然。
- **`StringNode` 等元操作符**：将标识符转换为字符串字面量时，使用专用的 `StringNode(ident)` 元函数，它在编译期生成一个 `TermAtomicLiteral` 节点，而非进行文本替换。
- **调用点作用域隔离**：宏展开使用宏**定义时**的环境作为父作用域，而非调用点的环境。这彻底阻止了调用点变量被意外捕获，代价是宏无法依赖调用点上下文。这种 “纯卫生” 设计极大地简化了宏的推理，是 Valkyrie MSP 的核心选择。

### 2.4 世界年龄（World Age）与阶段分离

“World age” 在 MSP 语境下指代不同阶段代码的可用性边界。Valkyrie 要求：**一个阶段内不能使用本阶段或以后阶段定义的元定义（macro / micro）**。基础宏和元函数通常定义在独立的 “meta 包” 中，它们作为模板被注册，不会在自身所在包内展开。而在 application 包的 staging 过程中，宏展开可能产生**新的**宏定义，这些新定义从其出现的位置开始生效，可用于后续代码，但不能递归自引用。这从根本上解决了世界年龄难题：

- 编译时，所有源文件被解析为 AST。
- `MetaStager` 维护一个动态的 `MacroRegistry`，初始包含从 meta 包静态注册的所有宏和 `micro`。
- Staging 按声明顺序处理 AST。当遇到宏调用时，使用当前注册表查找并展开；若展开结果中包含新的 `macro` 或 `micro` 声明，则立即注册到注册表中，供后续代码使用。
- 这保证了编译期代码所依赖的上下文在其被调用前已经完全固定，且 Stage 0 代码永远无法“逆流而上”影响编译期环境。

`StagingLevel` 的层级链严格遵循单向数据流：子层级可以通过 `Lookup` 查找父层级的绑定，但无法修改；父层级无法访问子层级的绑定。这从机制上杜绝了跨阶段副作用。

### 2.5 多阶段可组合性与高阶元编程

MSP 最强大的特性在于**可组合性**与**多阶段传递**：
- 宏 A 为一个结构体生成 `imply Serialize`，
- 宏 B 扫描当前作用域中所有带有 `Serialize` 实现的类型，自动生成 `deserialize` 方法。

在 Valkyrie 中，所有变换的输出都是标准的 AST 节点。更重要的是，宏展开的输出中可以包含**新的宏定义**。这意味着一个 Stage 1 的宏可以生成另一个 Stage 1 的宏（即 Stage 2 代码），后者在随后的 staging 过程中再展开为 Stage 0 代码。这一机制通过 `MetaStager` 的多趟递归展开和动态宏注册完整支持，实现了真正的多阶段编程。开发者可以构建分层的、高度模块化的元程序库。

## 3. 详细设计

### 3.1 语法规范

Valkyrie MSP 使用 `<% ... %>` 定界符来标记元代码。根据紧随 `<%` 的符号，分为**元语句**和**元表达式**：

- **元语句**：`<% match ... %>`、`<% if ... %>`、`<% loop ... %>`、`<% end ... %>` 等，用于控制编译期 AST 的裁剪、展开。
- **元表达式**：`<% expr %>`，编译期求值表达式并将其结果作为 AST 节点插入到所在位置。

所有 escape / splice 统一使用 `<% ... %>` 定界符，不再区分特殊符号。Splice 表达式中可以使用任意合法的编译期表达式。

宏调用使用 `@macro_name` 语法，派生属性使用 `[derive(MacroName)]`。**宏调用只能出现在语句或声明位置**（例如文件顶层、函数体内部语句），不能作为表达式的一部分。若需要在表达式位置生成代码，应使用 `micro` 函数或直接嵌入 `<% ... %>`。

#### 3.1.1 条件与模式匹配

```valkyrie
<% match target.spec %>
    <% case "linux" %>
        use linux::io;
    <% case "browser" %>
        use wasm::io;
    <% else %>
        @compile_error("unsupported platform");
<% end match %>
```

`match` 对编译期表达式求值，按字符串精确匹配 `case` 分支。内部可嵌套任何合法语句。

#### 3.1.2 循环展开

```valkyrie
<% loop field in node.fields %>
    s.write_field(StringNode(<% field.name %>), &self.<% field.name %>);
<% end loop %>
```

循环变量 `field` 绑定到 `node.fields` 集合中的每一个元素（在 staging 环境中，`node.fields` 会被求值为一个 `MetaCollection`）。每次迭代都产生一个语句，循环体内部的 `<% field.name %>` 被替换为表示字段名的标识符节点。循环展开的次数必须在编译期完全确定，且循环体内不能动态生成新的标识符名称（卫生性约束）。

#### 3.1.3 宏定义（普通宏与派生宏）

```valkyrie
// 普通宏
macro assert(node: ExpressionNode) {
    if !<% eval(node) %> {
        @compile_error("assertion failed")
    }
}

// 派生宏
[deriver]
macro serialize(node: ClassNode) {
    imply <% node.name %>: Serialize {
        fn serialize(self, s: &mut Serializer) {
            <% loop field in node.fields %>
                s.write_field(StringNode(<% field.name %>), &self.<% field.name %>);
            <% end loop %>
        }
    }
}
```

宏参数的类型指定了期望的 AST 节点种类（`ExpressionNode`、`ClassNode`、`AnyNode` 等）。宏体是标准的 MSP 代码，可以包含任意元语句和元表达式，甚至可以包含新的宏定义。

#### 3.1.4 元函数定义（micro）

```valkyrie
micro platform_init() {
    <% match target.spec %>
        <% case "linux" %> linux::init();
        <% case "browser" %> wasm::init();
    <% end match %>
}
```

`micro` 定义的函数在编译期执行，其调用点（使用 `@platform_init()`）会被展开为对应的代码。`micro` 函数可以访问 `target` 等编译期信息。`micro` 本质上是一种无参或带参的“语法模板”，与宏类似在注册表中存储，在调用时展开，因而也遵循世界年龄规则：不能在定义自身的包/作用域内被调用，除非定义在前。

### 3.2 元节点类型

在 AST 层面，Parser 会将 `<% ... %>` 块解析为以下节点，由 `MetaStager` 负责消除：

| 节点类型 | 说明 |
|:---|:---|
| `MatchTemplate` | `<% match ... %> ... <% end match %>` |
| `IfTemplate` | `<% if condition %> ... <% end if %>` |
| `Splice` | `<% expr %>` 元表达式，求值并替换为 AST 片段 |
| `Escape` | `<% var %>` 引用外层 staging level 的变量（底层实现与 Splice 统一） |
| `LoopTemplate` | `<% loop var in range %> ... <% end loop %>` |
| `LoopInTemplate` | `<% loop_in var in collection %> ... <% end loop_in %>` |
| `MacroInvocation` | 宏调用节点（`@macro_name`） |
| `MacroDecl` | 宏定义节点（`macro name(...) { ... }`） |
| `MicroDecl` | `micro` 函数定义节点 |

所有这些节点都实现 `ValkyrieNode` 接口，其 `IsMetaNode` 属性返回 `true`。`MetaStager` 的任务是遍历 AST 并将这些节点全部替换为标准的 Stage 0 节点（或节点列表），直到不再有任何元节点为止。

### 3.3 Staging Level 与绑定环境

`StagingLevel` 是核心数据结构，它封装了当前阶段的所有上下文信息：

```csharp
public class StagingLevel
{
    public int Level { get; }
    public CanonicalTriple Target { get; }
    public StagingLevel? Parent { get; }
    public Dictionary<string, MetaValue> Bindings { get; } = new();

    public string Arch => Target.Arch;
    public string Impl => Target.Impl;  // Vendor alias
    public string Spec => Target.Spec;  // OS alias
    public string ABI  => Target.ABI;

    public StagingLevel(int level, CanonicalTriple target, StagingLevel? parent = null)
    {
        Level = level;
        Target = target;
        Parent = parent;
    }

    public MetaValue? Lookup(string name)
    {
        if (Bindings.TryGetValue(name, out var value))
            return value;
        return Parent?.Lookup(name);
    }

    public StagingLevel Deeper() => new StagingLevel(Level + 1, Target, this);
}
```

- `Level`：当前阶段编号，0 为运行时。
- `Target`：当前编译目标的三元组，用于条件编译。
- `Parent`：父级 staging level，形成链式作用域。宏展开时，子层级的 `Parent` 被设置为**宏定义时**的 staging level，而非调用点，以此实现纯卫生性。
- `Bindings`：当前层级引入的变量（如宏参数、循环变量）。
- `Lookup`：沿 Parent 链向上查找变量，实现词法作用域。
- `Deeper`：创建子层级，用于宏展开、循环体展开等。

### 3.4 元值体系（MetaValue）

为了在 staging 环境中传递求值结果，Valkyrie 定义了一套元值类型：

```csharp
public abstract class MetaValue { }
public class MetaAstValue : MetaValue { public ProgramRoot Ast; }
public class MetaStringValue : MetaValue { public string Value; }
public class MetaIntValue : MetaValue { public long Value; }
public class MetaBoolValue : MetaValue { public bool Value; }
public class MetaCollectionValue : MetaValue { public List<MetaValue> Elements; }
public class MetaRangeValue : MetaValue { public long Start; public long End; }
```

在 staging 求值过程中，所有表达式求值结果都封装为上述类型。当 escape 需要将 `MetaValue` 转换回 AST 节点时，执行以下规则：

- `MetaAstValue` → 直接嵌入其 `Ast` 子树。
- `MetaStringValue` → 生成 `TermAtomicLiteral` 字符串节点。
- `MetaIntValue` → 生成数字字面量节点。
- `MetaBoolValue` → 生成 `true` 或 `false` 标识符节点。
- 集合/范围类型不允许直接 escape，只能在循环语句中解构。

### 3.5 编译期求值

`MetaStager` 包含一个递归求值器，能够在 staging 环境中执行常量折叠和简单运算。支持的表达式包括：

- **标识符**：查找 `Bindings` 及内置变量（`arch`, `impl`, `spec`, `abi`, `target` 等）。
- **成员访问**：如 `target.arch`，通过查找对象的内置属性获得。
- **字面量**：整数、字符串。
- **二元运算**：目前支持 `==`、`!=` 比较，返回 `MetaBoolValue`。
- **范围字面量**：`0..4` 求值为 `MetaRangeValue`。
- **数组字面量**：`[1,2,3]` 求值为 `MetaCollectionValue`。
- **内置元操作**：`sizeof(T)`、`StringNode(ident)`、`type_of(expr)` 等。

关于 `sizeof(T)` 的注意：由于 staging 发生在类型检查之前，`sizeof` 仅能应用于**编译器已知布局的类型**，包括所有内建基本类型（整数、浮点、布尔等）、指针及已知大小的平台相关类型（如 `usize`）。若 `T` 是尚未解析的自定义类型，`sizeof` 将报错。未来可考虑将其部分推迟到类型检查阶段实现。

元操作 `StringNode` 的实现：

```csharp
MetaValue EvaluateStringNode(MetaValue arg)
{
    if (arg is MetaAstValue astVal && astVal.Ast is IdentifierNode ident)
    {
        var literalNode = new TermAtomicLiteral(ident.Name);
        return new MetaAstValue(literalNode);
    }
    throw new CompileError("StringNode expects an identifier");
}
```

这完全避免了文本拼接，保证了卫生性。

### 3.6 宏系统设计

#### 3.6.1 宏的定义与动态注册

宏定义可以出现在 meta 包或 application 包的任意顶层或模块内。`MetaStager` 初始时从一个静态构建的 `MacroRegistry` 开始，该注册表包含所有 meta 包中提取的宏和 `micro` 定义。这些静态宏的定义体被保留为未展开的模板，并记录其定义时的 `StagingLevel`（包含 target 等编译期上下文）。

```csharp
public class MacroDef
{
    public string Name;
    public List<Parameter> Parameters;
    public FunctionBody Body;         // 仍包含元节点的 AST
    public bool IsDeriver;
    public StagingLevel DefinitionLevel; // 定义时的 staging 环境
}
```

在 staging application 包时，`MetaStager` 按声明顺序遍历 AST。当遇到 `MacroDecl` 或 `MicroDecl` 节点时，立即将其转换为 `MacroDef` 并**动态注册**到当前的 `MacroRegistry` 中。这一设计使得前一个宏展开可以生成后面的宏定义，实现多阶段传递。

#### 3.6.2 宏的调用展开与参数校验

当 `MetaStager` 遇到 `MacroInvocation` 节点时，执行以下步骤：

1. 从当前 `MacroRegistry` 查找宏定义；若未找到则报错。
2. 校验实参数量与形参数量一致。
3. 对每个参数，检查实参 AST 节点的类型是否与声明的期望类型兼容（例如要求 `ClassNode`，则实参必须为 `ClassNode` 或其子类）。类型不匹配立即报告错误。
4. 创建新的子 `StagingLevel`，其 `Parent` 设为宏**定义时**的 `DefinitionLevel`（保证卫生性，不暴露调用点作用域）。
5. 将实参 AST 节点绑定为 `MetaAstValue` 存入子层级的 `Bindings`。
6. 调用 `StageDeclarations(macro.Body.Statements, childLevel)` 展开宏体。
7. 将展开结果（`List<ValkyrieNode>`）插入到调用点，替换 `MacroInvocation` 节点。

由于宏调用只允许在语句/声明位置，展开结果扁平化插入是安全的，不会破坏语法结构。

#### 3.6.3 派生宏

`[derive(Serialize)]` 的处理流程类似，实参是随后的整个 `ClassNode`。编译器将派生宏的展开结果附加到类定义之后。

### 3.7 错误处理与诊断

MSP 变换发生在类型检查之前，因此**纯粹的语法错误**已在 Parse 阶段捕获。Staging 过程中可能产生以下错误：
- `@compile_error("message")`：立即终止编译并输出错误。
- 引用未定义的宏或 `micro`。
- Escape 引用不存在的 staging 变量。
- 求值类型错误（如对 `MetaIntValue` 进行成员访问）。
- 宏展开产生的代码**在后续 Analyze 阶段**可能报告类型错误、未解析名称等正常编译错误。这些错误会关联到宏展开前的源位置（通过 source span 传播），以便开发者定位。

### 3.8 包隔离与同包引用检查

Meta 包中的宏/`micro` 仅作为模板注册，不会在其自身内部展开调用。对于 application 包，允许同一包内定义宏并在后续代码中使用，但禁止**循环依赖**。具体检查采用保守的静态规则：

- 扫描 `MacroDecl` 和 `MicroDecl` 的体（函数体），收集其内部出现的所有宏调用名称。
- 如果宏 A 的体直接或间接调用了同包中定义在 A 之后的宏 B，且 B 的体也调用了 A，则报告循环依赖错误。由于动态注册允许宏在定义后即可用，这个检查可通过计算宏调用图的强连通分量来实现，保留“定义在前”的合法依赖。
- 不进行更复杂的运行时（即编译期）依赖分析，因为 staging 是顺序进行的，只要宏体展开时所需的宏已存在即可。

## 4. 参考实现（C# 语言）

### 4.1 整体架构

`MetaStager` 类约 800 行，公开方法为：

```csharp
public class MetaStager
{
    private MacroRegistry _macroRegistry;
    private int _stagingDepth = 0;

    public ProgramRoot Stage(ProgramRoot ast, CanonicalTriple target, MacroRegistry initialMacros);
    // 内部主入口：顺序处理声明，并动态维护 _macroRegistry
    private List<ValkyrieNode> StageDeclarations(IEnumerable<ValkyrieNode> decls, StagingLevel level);
    // 核心递归消除
    private List<ValkyrieNode> StageRecursive(IEnumerable<ValkyrieNode> nodes, StagingLevel level);
    // 单节点分发
    private object? StageNode(ValkyrieNode node, StagingLevel level);
}
```

### 4.2 管线集成

在 `ValkyrieCompiler.cs` 中：

```csharp
// 多文件编译
var units = files.Select(f => parser.Parse(f)).ToList();
var macroRegistry = BuildStaticRegistry(metaPackages);
var stager = new MetaStager();
var initialLevel = new StagingLevel(0, plan.CanonicalTriple, null);
var stagedUnits = units.Select(u => 
    (CompilationUnit)stager.Stage(u, initialLevel, macroRegistry)
).ToArray();
var mergedAst = Merge(stagedUnits);
var analyzed = analyzer.Analyze(mergedAst);
```

### 4.3 完整的递归消除与动态宏注册

`StageRecursive` 的核心改进：**深度遍历所有节点**，而不只是顶层块。任何 `ValkyrieNode` 的子节点都要被递归处理。我们通过一个内部辅助方法 `StageNodeRecursive` 实现 AST 的完整遍历，确保任何嵌套位置的 `Splice` 等元节点都被消除。

```csharp
private List<ValkyrieNode> StageRecursive(IEnumerable<ValkyrieNode> nodes, StagingLevel level)
{
    if (_stagingDepth > MaxStagingDepth)
        throw new CompileError("Maximum staging depth exceeded");
    _stagingDepth++;

    var result = new List<ValkyrieNode>();
    bool hasMeta = false;
    foreach (var node in nodes)
    {
        // 首先处理宏定义/micro定义：动态注册
        if (node is MacroDecl macroDecl)
        {
            var macroDef = BuildMacroDef(macroDecl, level);
            _macroRegistry.Register(macroDef.Name, macroDef);
            // 宏定义本身不产生运行时代码，从结果中移除（或保留为空）
            hasMeta = true;
            continue;
        }
        if (node is MicroDecl microDecl)
        {
            var microDef = BuildMacroDefFromMicro(microDecl, level);
            _macroRegistry.Register(microDef.Name, microDef);
            hasMeta = true;
            continue;
        }

        // 若节点为元节点，进行消除
        if (node.IsMetaNode)
        {
            hasMeta = true;
            var staged = StageNode(node, level);
            if (staged is List<ValkyrieNode> list)
                result.AddRange(list);
            else if (staged is ValkyrieNode single)
                result.Add(single);
            // null 表示消除
        }
        else
        {
            // 非元节点但可能有子节点包含元节点，需递归进入子节点
            var processed = StageSubNodes(node, level, out bool childHasMeta);
            result.Add(processed);
            if (childHasMeta) hasMeta = true;
        }
    }

    _stagingDepth--;

    // 若本趟发现了任何元节点（包括动态注册了新的宏），则需要再次遍历，因为新注册的宏可能在后面调用
    // 注意：此时 result 中可能仍包含 MacroInvocation 等节点，需要继续处理
    return hasMeta ? StageRecursive(result, level) : result;
}

// 对所有非元节点的子节点进行递归 staging
private ValkyrieNode StageSubNodes(ValkyrieNode node, StagingLevel level, out bool hasMeta)
{
    // 使用 Visitor 或 switch 处理各种 AST 节点类型，对其内部的子节点列表调用 StageRecursive
    // 示例仅展示结构，实际实现遍历所有可能包含语句/表达式的属性。
    hasMeta = false;
    switch (node)
    {
        case FunctionBody body:
            var stmts = StageRecursive(body.Statements, level);
            hasMeta |= (stmts != body.Statements);
            return new FunctionBody(body.Attributes, stmts);
        case IfStatement ifStmt:
            var thenBody = StageRecursive(ifStmt.ThenBlock, level);
            var elseBody = ifStmt.ElseBlock != null ? StageRecursive(ifStmt.ElseBlock, level) : null;
            var cond = StageExpression(ifStmt.Condition, level, out bool condMeta); // 表达式也可能有 splice
            hasMeta |= condMeta || (thenBody != ifStmt.ThenBlock) || (elseBody != ifStmt.ElseBlock);
            return new IfStatement(cond, thenBody, elseBody);
        // ... 其他所有语句、表达式容器类似处理
        default:
            // 叶子节点
            return node;
    }
}
```

关键点：`StageSubNodes` 覆盖所有可能的 AST 节点，确保任何位置的元节点都能被发现。`Splice` 可在表达式内部出现，故表达式遍历也要递归。

### 4.4 关键方法实现

#### StageNode 分发

```csharp
private object? StageNode(ValkyrieNode node, StagingLevel level)
{
    return node switch
    {
        MatchTemplate match       => StageMatch(match, level),
        IfTemplate ift            => StageIf(ift, level),
        Splice splice             => StageSplice(splice, level),
        Escape escape             => StageEscape(escape, level),
        LoopTemplate loop         => StageLoop(loop, level),
        LoopInTemplate loopIn     => StageLoopIn(loopIn, level),
        MacroInvocation invoke    => StageMacroInvocation(invoke, level),
        _                         => node
    };
}
```

#### 宏调用展开（含参数校验）

```csharp
private object? StageMacroInvocation(MacroInvocation invocation, StagingLevel level)
{
    if (!_macroRegistry.TryGet(invocation.MacroName, out var macroDef))
        throw new CompileError($"Macro '{invocation.MacroName}' not found");

    // 参数数量检查
    if (invocation.Arguments.Count != macroDef.Parameters.Count)
        throw new CompileError($"Macro '{invocation.MacroName}' expects {macroDef.Parameters.Count} arguments, got {invocation.Arguments.Count}");

    // 参数类型校验
    for (int i = 0; i < macroDef.Parameters.Count; i++)
    {
        var expectedType = macroDef.Parameters[i].NodeType; // 如 "ExpressionNode", "ClassNode"
        var argNode = invocation.Arguments[i];
        if (!IsNodeTypeCompatible(argNode, expectedType))
            throw new CompileError($"Argument {i+1} of macro '{invocation.MacroName}' must be a {expectedType}");
    }

    // 创建子层级，Parent 设为定义时的环境（纯卫生）
    var childLevel = macroDef.DefinitionLevel.Deeper();
    for (int i = 0; i < macroDef.Parameters.Count; i++)
    {
        var paramName = macroDef.Parameters[i].Name;
        var argNode = invocation.Arguments[i];
        childLevel.Bindings[paramName] = new MetaAstValue(argNode);
    }

    // 展开宏体
    var expanded = StageDeclarations(macroDef.Body.Statements, childLevel);
    return expanded;
}
```

#### StageLoop（集合/范围展开）

```csharp
private object? StageLoop(LoopTemplate loop, StagingLevel level)
{
    var range = EvaluateExpression(loop.Range, level);
    if (range is MetaRangeValue r)
    {
        var result = new List<ValkyrieNode>();
        for (long i = r.Start; i < r.End; i++)
        {
            var childLevel = level.Deeper();
            childLevel.Bindings[loop.Variable.Name] = new MetaIntValue(i);
            result.AddRange(StageDeclarations(loop.Body.Statements, childLevel));
        }
        return result;
    }
    else if (range is MetaCollectionValue coll)
    {
        var result = new List<ValkyrieNode>();
        foreach (var elem in coll.Elements)
        {
            var childLevel = level.Deeper();
            childLevel.Bindings[loop.Variable.Name] = elem;
            result.AddRange(StageDeclarations(loop.Body.Statements, childLevel));
        }
        return result;
    }
    throw new CompileError("Loop range must be a compile-time range or collection");
}
```

### 4.5 动态注册支持多阶段示例

通过动态注册，以下多阶段代码成为可能：

```valkyrie
// Stage 1 宏：生成一个 Stage 1 宏
macro define_getters(node: ClassNode) {
    <% loop field in node.fields %>
        // 动态生成一个新的宏，专门获取该字段
        macro get_<% field.name %>() {
            fn get_<% field.name %>(self: &Self) -> &_ {
                &self.<% field.name %>
            }
        }
    <% end loop %>
}

// 使用
@define_getters(MyStruct)
@get_x  // 此时 get_x 宏已在前一行被动态注册，可立即调用
@get_y
```

在此过程中，`define_getters` 展开的结果是多个 `macro get_...` 定义，`MetaStager` 立即将它们注册，后续 `@get_x` 便能成功调用。

## 5. 高级应用模式

### 5.1 跨平台抽象

利用 `target` 内置变量和条件展开，编写零开销的平台抽象层。未被选中的代码分支完全不会出现在最终 AST 中。

### 5.2 自动化序列化/反序列化

通过派生宏遍历类型字段，生成 `imply` 实现，完全消除样板代码。

### 5.3 编译期代码特化

根据目标架构特性（如 SIMD 宽度）生成不同展开次数的循环。

### 5.4 多阶段 DSL 编译

将小型 DSL 嵌入元函数，通过 staging 编译为高效代码，无需运行时解释开销。

### 5.5 可组合的代码分析与生成器

宏输出可包含新宏，构建高阶元程序。例如，自动为所有公共函数生成基准测试框架，其输出又是一个参数化宏，根据配置生成不同测量代码。

## 6. 总结与展望

Valkyrie 的 MSP 系统通过严格的设计约束——卫生性、世界年龄顺序、动态宏注册、完整的 AST 遍历、语法位置限制——提供了一个强大且安全的多阶段编程环境。参考实现虽紧凑，却完整支持了跨平台条件编译、派生宏、编译期循环展开、以及任意深度的宏生成宏等高阶特性。

未来扩展方向：
- **部分推迟求值**：将依赖于类型信息的元操作（如增强的 `sizeof`、`align_of`）推迟到 Analyze 阶段后执行，或引入类型占位符。
- **增量 staging**：缓存 staging 结果以加速重编译。
- **更丰富的诊断**：展示宏展开的完整链，帮助调试复杂多阶段变换。
- **类型化 staging 接口**：允许宏声明其输出符合某种语法类别，进一步增强安全性。