# Wire

Atlas 用 **Wire** 组装 System / Controller 所需的协作对象，而不是在业务代码里 `new` 一棵依赖树。

- [从 IoC/DI 到 Wire](history.md)
- [Wire 机制](wire.md)
- [非真实 Wire：mock / sink / null](doubles.md)
- [Wire 与代数效应](effects.md)

请求横切与 AOP 见 [Middleware · AOP](../middleware/aop.md)。

包内实现摘要见 [`projects/atlas/readme.md`](../../../projects/atlas/readme.md)。
