# 来源

- 源码基线：E:/xiugai/srctianjia；原目录未修改。PLL_INIT来自同迁移包dependencies。
- 旧测试：xiugai/sim的CDC、reset、FFT自检，未改其原件。
- 接口stub：D:/fpga26/boards/tang_mega_138k_pro/sim/visual_primitive_stubs.v，只供编译层次核对，不是硬件模型。
- 正式时序依据：[AMD/Xilinx XAPP1014](https://docs.amd.com/api/khub/documents/SXRSvHFNxfdzpufcXyWw2w/content)，1080p30为74.25MHz、2200×1125；[PG290视频分辨率表](https://docs.amd.com/r/en-US/pg290-v-smpte-uhdsdi-rx-ss/Video-Resolutions)。
- PLL原语关系和1/8步进：[Gowin UG306 Arora V Clock](https://www.gowinsemi.com/upload/database_doc/2465/document_ja/65c1e6a70eb0d.pdf)，内部反馈Fvco=(Fin/IDIV)×FBDIV×MDIV。
- PFD/VCO/串行器范围：[Gowin GW5AST DS1239](https://cdn.gowinsemi.com.cn/DS1239E.pdf)。本轮联网核对，参数合法性不等于厂家实现通过。

新增Hilbert系数按数学公式生成：63tap，h[k]=2/(pi×(k−31))（k−31为奇数时），乘Hamming窗，Q1.15量化；reference/hilbert_coefficients.json保存32个非零系数。无预录PCM，无预制李萨如图。
