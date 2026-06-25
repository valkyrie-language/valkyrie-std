# ECS 扩展

Valkyrie 语言的 ECS 扩展为游戏引擎实体-组件-系统架构提供一等公民语法，直接映射到 Gnosis 引擎的 ECS 子系统。

## 设计理念

许多语言只能通过库和约定去模拟 ECS；`Valkyrie` 选择把这些概念直接提升为语言原语：

| 面向框架的写法 | Valkyrie |
|:---|:---|
| 通过普通数据类型手动注册组件 | `component Position { ... }` |
| 通过调度对象声明系统逻辑 | `system MovementSystem { ... }` |
| 通过查询 API 组合筛选条件 | `query all = Query.all(Position, Velocity)` |
| 通过显式取值接口访问组件 | `entity.position` |

## Component 声明

组件是纯数据容器，对应 Gnosis ECS 的 Archetype 字段。

### 基础组件

```v
component Position {
    x: f32;
    y: f32;
}

component Velocity {
    dx: f32;
    dy: f32;
}

component Health {
    current: f32;
    max: f32;
}
```

### 带默认值的组件

```v
component Transform {
    x: f32 = 0.0;
    y: f32 = 0.0;
    rotation: f32 = 0.0;
    scale: f32 = 1.0;
}
```

### 带特性标注的组件

```v
[serializable]
[replicated]
component PlayerState {
    health: f32;
    score: i32;
}
```

### 组件约束

- 组件仅包含数据字段，不包含方法
- 字段类型必须是稳定的数据语义类型
- 不允许嵌套组件引用；跨实体关系应显式使用实体标识或等价引用

## System 声明

系统是逻辑处理器，包含查询定义和生命周期回调。

### 基础系统

```v
system MovementSystem {
    query all = Query.all(Position, Velocity);

    on_update(frame: Frame) {
        loop entity in query.all {
            entity.position.x += entity.velocity.dx * frame.dt;
            entity.position.y += entity.velocity.dy * frame.dt
        }
    }
}
```

### 查询类型

| 方法 | 说明 | 示例 |
|:---|:---|:---|
| `Query.all(...)` | 包含所有指定组件 | `Query.all(Position, Velocity)` |
| `Query.any(...)` | 包含任一指定组件 | `Query.any(Health, Shield)` |
| `Query.none(...)` | 排除指定组件 | `Query.all(Player).none(AI)` |

查询可链式组合：

```v
query enemies = Query.all(Health, Team).none(Player);
query destructible = Query.all(Health).none(Invulnerable);
```

### 生命周期回调

| 回调 | 签名 | 说明 |
|:---|:---|:---|
| `on_update` | `(frame: Frame)` | 每帧调用 |
| `on_create` | `(entity: Entity)` | 实体创建时调用 |
| `on_destroy` | `(entity: Entity)` | 实体销毁时调用 |
| `on_enable` | `(entity: Entity)` | 组件启用时调用 |
| `on_disable` | `(entity: Entity)` | 组件禁用时调用 |

### 系统执行顺序

```v
[execute_before(PhysicsSystem)]
[execute_after(InputSystem)]
system MovementSystem {
    # ...
}
```

## Entity 操作

### 实体创建

```v
let entity = Entity.create();
entity.add(Position { x: 0.0, y: 0.0 });
entity.add(Velocity { dx: 1.0, dy: 0.0 });
```

### 实体销毁

```v
entity.destroy();
```

### 组件访问

```v
let pos = entity.position;           # 读取组件
entity.position.x += 1.0;           # 修改组件字段
entity.has(Position);                # 检查组件是否存在
entity.remove(Position);             # 移除组件
```

