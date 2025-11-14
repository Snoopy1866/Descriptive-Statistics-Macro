# sas-summarize

![Github License](https://img.shields.io/github/license/Snoopy1866/sas-summarize)
![GitHub Release](https://img.shields.io/github/v/release/Snoopy1866/sas-summarize)

> [!IMPORTANT]
>
> [v2](https://github.com/Snoopy1866/sas-summarize) 和 [v1](https://github.com/Snoopy1866/sas-summarize/tree/v1) 互不兼容，
> 如果你使用的是 v1 版本，请参考 [v1 帮助文档](https://github.com/Snoopy1866/sas-summarize/tree/v1)。

## 简介

适用于简单汇总统计的 SAS 宏程序，可满足定量、定性，单组、多组和简单假设检验的分析需求。

以下编码环境可用：

- [gb2312](src/gb2312/)
- [gb18030](src/gb18030/)
- [gbk](src/gbk/)
- [utf8](src/utf8/)
- [utf16](src/utf16/)

## 详细文档

| 🧩 程序名称            | ✨ 描述                 | 📚 文档                                  |
| ---------------------- | ----------------------- | ---------------------------------------- |
| `%qualify`             | 单组定性汇总            | [↗️](docs/qualify/readme.md)             |
| `%qualify_multi`       | 多组定性汇总            | [↗️](docs/qualify_multi/readme.md)       |
| `%qualify_multi_test`  | 多组定性汇总 + 假设检验 | [↗️](docs/qualify_multi_test/readme.md)  |
| `%quantify`            | 单组定量汇总            | [↗️](docs/quantify/readme.md)            |
| `%quantify_multi`      | 多组定量汇总            | [↗️](docs/quantify_multi/readme.md)      |
| `%quantify_multi_test` | 多组定量汇总 + 假设检验 | [↗️](docs/quantify_multi_test/readme.md) |
| `%crosstab`            | 交叉表                  | [↗️](docs/crosstab/readme.md)            |
| `%desc_coun`           | 单组定性分层汇总        | [↗️](docs/desc_coun/readme.md)           |
