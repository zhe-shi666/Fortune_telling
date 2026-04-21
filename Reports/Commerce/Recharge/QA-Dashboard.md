# QA Dashboard

- page: Commerce/Recharge/RechargeCenter
- gateMode: advisory
- readinessScore: 88
- scoreBreakdown: base 100, -8 (syncRechargeCenterToBackend pending), -4 (createRechargeOrder real payment pending)
- assumptions:
  - 当前测试验证选择流程与购买说明文案，不验证真实支付或财务账本。

## Coverage
- scenarios: ideal, loading, empty, error
- transactionStepsCovered: step-1, step-2, step-3, step-4

## Matrix
- `ideal`: 成功加载余额、套餐与支付方式
- `ideal`: 成功加载余额、套餐与支付方式
- `error`: 服务失败时展示错误提示
- `submit`: 选择默认套餐和支付方式后返回克制的购买说明文案
- `persist`: 充值未开放时，本地余额不会被误写入
- `back`: 点击返回关闭充值页

## Skipped
- item: 真实支付链路测试
  reason: 当前版本明确不接支付 SDK 与订单回调
- item: 快照测试
  reason: 项目未引入快照框架

## Warnings
- type: pending-sync
  target: syncRechargeCenterToBackend
  action: 若后续接入真实余额接口，需要补齐本地展示余额与远端真实余额的切换策略
- type: critical-stub
  target: createRechargeOrder
  action: 接入真实支付前，不要把当前页面的未开放提示视为已完成真实充值
