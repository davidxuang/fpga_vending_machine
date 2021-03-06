设计 FPGA 模块模拟自动售货机的工作过程。

1. 售货机有两个进币孔。一个是输入硬币，一个是输入纸币，硬币的识别范围是 1 元的硬币，纸币的识别范围是 5 元，10 元，20 元，50 元。乘客可以连续多次投入纸币；
2. 顾客可以选择的商品种类有 16 种，分别为 A11‒A44，顾客可以通过输入商品的编号来实现商品的选择；价格如下表所示

    ```
    ┌─────────┬────────┬─────────┬────────┐
    │ A11:  3 │ A12: 4 │ A13:  6 │ A14: 3 │
    ├─────────┼────────┼─────────┼────────┤
    │ A21: 10 │ A22: 8 │ A23:  9 │ A24: 7 │
    ├─────────┼────────┼─────────┼────────┤
    │ A31:  4 │ A32: 6 │ A33: 15 │ A34: 8 │
    ├─────────┼────────┼─────────┼────────┤
    │ A41:  9 │ A42: 4 │ A43:  5 │ A44: 5 │
    └─────────┴────────┴─────────┴────────┘
    ```

3. 顾客选择完商品后，可以选择需要的数量，数量为 1‒3 件；
4. 顾客可以继续选择商品及其数量，最多可选择两种商品；
5. 选择完货品，按确认键确认；
6. 系统计算并显示出所需金额；
7. 顾客此时可以投币，并且显示已经投币的总币值。当投币值达到或超过所需币值后，售货机出货，并扣除所需金额，并找出多余金额；
8. 找零时需要手动找零，每次一元。比如需找零 3 元，则需要按三次手动找零键；
9. 在投币期间，顾客可以按取消键取消本次操作，可以按手动找零键退出硬币。如果没有退出，可以重新选择货品进行交易。
