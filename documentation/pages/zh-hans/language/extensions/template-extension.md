# Template 扩展

Valkyrie 语言的 Template 扩展提供元代码块语法，将 Valkyrie 语句模板化用于编译期代码生成和模板渲染。

## 设计理念

Valkyrie 核心语言提供 `<% ... %>` 元代码块，将已有的语句语法模板化：

| Valkyrie 语句                 | 模板化                                     | 说明                             |
| :-------------------------- | :-------------------------------------- | :----------------------------- |
| `if xxx { ... }`            | `<% if xxx %> ... <% end %>`            | if 语句 → if template node       |
| `loop item in list { ... }` | `<% loop item in list %> ... <% end %>` | loop 语句 → loop template node   |
| `match expr { ... }`        | `<% match expr %> ... <% end %>`        | match 语句 → match template node |
| `<% expr %>`                | 表达式求值                                   | 编译期求值并输出结果                     |

## 解析规则

### 词法分析

遇到 `<%` 后，查看下一个 token：

1. 如果是 keyword → 模板化语句（MetaBlockStart）
2. 如果不是 keyword → 表达式（MetaExpression）

```
<% if x > 0 %>          → keyword "if" → 模板化 if 语句
<% loop item in list %>  → keyword "loop" → 模板化 loop 语句
<% x + y %>             → 不是 keyword → 表达式求值
```

> **注意**：Valkyrie 不支持 `<%=`、`<%-`、`<%_` 等变体。因为 Valkyrie 不是空格敏感的语言，最终输出的是指令而非文本，空格控制没有意义。

### 节点类型

| 概念                    | 语法                              | 说明          |
| :-------------------- | :------------------------------ | :---------- |
| **if statement node** | `if xxx { ... }`                | Valkyrie 语句 |
| **if fragment node**  | `<% if xxx %>`                  | 模板化语句的开头片段  |
| **if template node**  | `<% if xxx %> ... <% end if %>` | 完整的模板化 if 块 |

`end` 是 template 模式下的关键词，用于闭合模板化语句块：

```
<% if condition %>
    ...
<% end %>

<% loop item in list %>
    ...
<% end %>

<% match expr %>
    ...
<% end %>
```

### end 闭合规则

默认使用 `<% end %>` 栈匹配（LIFO，最近优先），必要时使用显式 `<% end if %>` 消除歧义：

| 语法                | 行为                        |
| :---------------- | :------------------------ |
| `<% end %>`       | 闭合最近的未闭合模板化语句             |
| `<% end if %>`    | 显式闭合 if（验证栈顶是否为 if）       |
| `<% end loop %>`  | 显式闭合 loop（验证栈顶是否为 loop）   |
| `<% end match %>` | 显式闭合 match（验证栈顶是否为 match） |

**无歧义时用** **`<% end %>`**：

```
<% if condition %>
    ...
<% end %>              ← 闭合 if，无歧义
```

**嵌套歧义时用显式** **`<% end if %>`**：

```
<% loop item in list %>
    <% if condition %>
        ...
    <% else %>          ← if 的 else
        ...
    <% end if %>         ← 显式闭合 if，避免与 loop 混淆
<% end %>               ← 闭合 loop
```

**显式闭合类型不匹配时报错**：

```
<% if condition %>
    ...
<% end loop %>          ← 错误：栈顶是 if，不是 loop
```



## 语言变体

| 变体       | 分隔符         | 文件扩展名   |
| :------- | :---------- | :------ |
| **Dora** | `<% ... %>` | `.dora` |
| **Doki** | `{% ... %}` | `.doki` |

