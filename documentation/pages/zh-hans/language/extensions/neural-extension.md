# Neural 扩展

Valkyrie 语言的 Neural 扩展为神经网络和深度学习提供领域特定语法，支持张量操作、模型定义与推理。

## 设计理念

传统深度学习框架（PyTorch、TensorFlow）通过库 API 定义模型，Valkyrie Neural 扩展将神经网络概念提升为语言原语：

| 传统方式 | Valkyrie Neural |
|:---|:---|
| Python API（`torch.nn.Linear`） | `layer` 一等公民声明 |
| 运行时张量检查 | 编译期张量形状验证 |
| 胶水代码连接层 | 声明式数据流图 |
| 手动设备分配 | 自动设备亲和性推导 |

## 张量类型

### 基础张量

```v
using neural::{Tensor, f32, i32}

let x: Tensor<f32, [32, 64]> = tensor.rand([32, 64])
let y: Tensor<f32, [_, 64]> = tensor.rand([16, 64])
```

张量类型编码：`Tensor<T, Shape>`，其中 `Shape` 是编译期维度元组，`_` 表示动态维度（运行时确定）。

### 张量操作

```v
let a = tensor.rand([32, 64])
let b = tensor.rand([32, 64])
let c = a + b
let d = a * 2.0
let e = tensor.matmul(a, b.transpose())
let f = tensor.relu(c)
```

支持的操作包括算术运算、点积、矩阵乘、激活函数。

## 层声明

```v
layer MyLayer {
    weight: Tensor<f32, [128, 256]>;
    bias: Tensor<f32, [256]>;

    forward(x: Tensor<f32, [_, 128]>) -> Tensor<f32, [_, 256]> {
        let y = tensor.matmul(x, self.weight)
        let z = y + self.bias
        tensor.relu(z)
    }
}
```

层是参数化计算模块，包含可训练参数和 `forward` 方法。

## 模型声明

```v
model SimpleClassifier {
    layer1: Linear<128, 256>;
    layer2: Linear<256, 10>;

    forward(x: Tensor<f32, [_, 128]>) -> Tensor<f32, [_, 10]> {
        let h = tensor.relu(self.layer1.forward(x))
        self.layer2.forward(h)
    }
}
```

模型组合多个层，定义完整的前向传播计算图。

## 训练循环

```v
model TrainingLoop {
    optimizer: Adam<SimpleClassifier>;
    loss: CrossEntropyLoss;

    train_epoch(model: mut SimpleClassifier, data: DataLoader) -> f32 {
        let mut total_loss = 0.0
        loop (x, y) in data {
            let pred = model.forward(x)
            let loss = self.loss.compute(pred, y)
            self.optimizer.step(loss)
            total_loss += loss
        }
        total_loss / data.size()
    }
}
```

## 推理

```v
micro classify_image(image: Tensor<f32, [1, 28, 28]>) -> i32 {
    let model = ModelLoader.load<SimpleClassifier>("model.bin")
    let flat = image.reshape([1, 784])
    let logits = model.forward(flat)
    tensor.argmax(logits)
}
```