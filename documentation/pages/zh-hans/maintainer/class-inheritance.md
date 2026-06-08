# 类继承降级

## 概述

Valkyrie 的类继承是语法糖——继承关系在语义分析阶段被展开为字段组合。编译器不维护运行时的继承链，而是将基类字段内联到子类中，通过自动命名字段访问基类成员。

## 继承的展开

### 简单继承

```valkyrie
class Animal
    name: string
    age: i32

class Dog(Animal)
    breed: string
```

TypeChecker 展开为：

```valkyrie
class Dog
    animal: Animal    // 自动生成：类型名 snake_case
    breed: string
```

### 具名继承

```valkyrie
class Dog(pet: Animal)
    breed: string
```

展开为：

```valkyrie
class Dog
    pet: Animal       // 使用显式指定的字段名
    breed: string
```

### 多继承

```valkyrie
class Duck(Flying, Swimming)
    quack_volume: f32
```

展开为：

```valkyrie
class Duck
    flying: Flying      // Flying → flying（自动 snake_case）
    swimming: Swimming  // Swimming → swimming（自动 snake_case）
    quack_volume: f32
```

## 自动命名规则

基类字段名由类型名自动生成：将 PascalCase 类型名转换为 snake_case。

转换规则：在连续大写字母后遇到小写字母时，于大写字母前插入下划线，全部转为小写：

| 类型名 | 自动字段名 |
|:---|:---|
| `Base` | `base` |
| `MyComponent` | `my_component` |
| `HTTPServer` | `http_server` |

## 多继承冲突检测

### 字段名冲突

若自动生成的字段名与子类自有字段名冲突，报告 VALK3002。

### 具名冲突

若多个具名继承使用相同的字段名，报告 VALK3003。

### 方法冲突消歧

当多个基类提供同名方法时：

1. **全限定调用** `Base1::foo(self)` 在编译时解析为特定基类的方法
2. **using 声明** `using Base1::foo` 将基类方法提升为子类的首选实现
3. **MRO** 仅影响 `super.method()` 在子类成员函数内部的解析

## MRO 在编译中的处理

编译器在类声明处理阶段构建每个类的 MRO 序列：

```
MRO 计算：
1. 从当前类开始
2. 按基类声明顺序（从左到右）递归展开每个基类的 MRO
3. 合并为线性序列，去重保留最早出现

示例：
class GrandBase { }
class Base1(GrandBase) { }
class Base2 { }
class Child(Base1, Base2) { }

MRO(Child) = [Child, Base1, GrandBase, Base2]
```

`super.method()` 在子类内部按此序列查找第一个定义了 `method` 的类。

## 在管线中的位置

```
TypeChecker Pass 2（声明检查）
  │
  ├── 展开继承语法糖
  │     ├── 生成基类字段（自动或具名命名）
  │     ├── 检测字段名冲突
  │     └── 构建 MRO 序列
  ├── Pass 3: 体检查
  │     └── 解析 super.method() 按 MRO 查找
  │
  └── SemanticModel（继承已展开，后续阶段不感知原始继承关系）

HirBuilder
  │
  └── 接收的是展开后的类型定义，无继承概念
```

## 继承校验

| 规则 | 检测阶段 | 错误码 |
|:---|:---|:---|
| 同类型必须具名 | Pass 2 | VALK3001 |
| 字段名冲突 | Pass 2 | VALK3002 |
| 具名冲突 | Pass 2 | VALK3003 |
| 循环继承 | Pass 2 | VALK3004 |

## 设计决策

类继承在 TypeChecker 阶段完全展开的原因：

1. **简化下游**：HIR/MIR/LIR 不需要处理继承关系，统一为字段组合
2. **消除虚调用**：方法分派在展开后通过现有三级分派机制处理，不需要引入虚函数表
3. **零运行时开销**：基类访问等价于字段访问，无间接跳转
4. **编译期所有关系已知**：Valkyrie 不使用动态类加载，继承关系在编译期完全确定