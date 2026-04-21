# Logic Report

- page: Commerce/Recharge/RechargeCenter
- gateMode: advisory
- assumptions:
  - 充值中心展示数据与提交结果当前由 `LocalRechargeCenterService` 提供，页面用于承接未来真实内购方向。
  - `submitRecharge` 当前不发起真实支付，也不写入本地余额；点击后统一返回克制的购买说明文案，不制造真实成交误导。

## Critical Stubs
- name: syncRechargeCenterToBackend
  criticality: medium
  blockingRelease: false
  reason: 真实余额、套餐与支付渠道接口尚未接入
- name: createRechargeOrder
  criticality: medium
  blockingRelease: false
  reason: 当前只返回未开放提示，不生成真实订单

## Transaction Steps
- id: step-1
  name: load-center
  criticality: high
  rollbackRequired: false
- id: step-2
  name: select-plan
  criticality: medium
  rollbackRequired: false
- id: step-3
  name: select-payment-method
  criticality: medium
  rollbackRequired: false
- id: step-4
  name: submit-recharge-intent
  criticality: high
  rollbackRequired: false

## Failure Injection Points
- stepId: step-1
  target: load-center
  suggestedFailure: 抛出 `RechargeCenterServiceError.unavailable`
- stepId: step-4
  target: submit-recharge-intent
  suggestedFailure: 在未选套餐或支付方式时触发 `nothingSelected`
