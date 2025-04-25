# Descriptive-Statistics-Macro

> [!WARNING]
>
> [v1](https://github.com/Snoopy1866/sas-summarize/tree/v1) 版本已不再维护，请使用 [v2](https://github.com/Snoopy1866/sas-summarize/tree/v2) 版本；
> [v2](https://github.com/Snoopy1866/sas-summarize/tree/v2) 版本项目已更名为 **`sas-summarize`**。

以下列举的是一些 v1 版本存在的已知问题，已在 v2 版本中修复：

| 宏程序                                   | 问题                                                     | PR                                                         |
| ---------------------------------------- | -------------------------------------------------------- | ---------------------------------------------------------- |
| `%quantify`                              | 参数 `stat_note` 默认值 `#auto` 的大小写未正确识别       | [#81](https://github.com/Snoopy1866/sas-summarize/pull/81) |
| `%quantify_multi_test`                   | 列 `value_1` 长度不足以容纳统计量名称 `Wilcoxon秩和检验` | [#82](https://github.com/Snoopy1866/sas-summarize/pull/82) |
| `%quantify_multi, %quantify_multi_test`  | 参数 `debug` 未能生效                                    | [#83](https://github.com/Snoopy1866/sas-summarize/pull/83) |
| `%qualify`                               | `缺失` 分类的名称和位置错误                              | [#89](https://github.com/Snoopy1866/sas-summarize/pull/89) |
| `%qualify`                               | `missing_position = first` 不生效                        | [#90](https://github.com/Snoopy1866/sas-summarize/pull/90) |
| `%qualify`                               | 未指定参数 `missing` 导致程序中断                        | [#91](https://github.com/Snoopy1866/sas-summarize/pull/91) |
| `%quantify_multi`, `quantify_multi_test` | 变量 `times_i_fmt` 意外输出的问题                        | [#93](https://github.com/Snoopy1866/sas-summarize/pull/93) |
| `%quantify_multi`, `quantify_multi_test` | 参数 `by` 的默认值错误的问题                             | [#94](https://github.com/Snoopy1866/sas-summarize/pull/94) |

# 简介

描述性统计 SAS 宏程序

支持以下编码环境：

- [gb2312](src/gb2312/)
- [gb18030](src/gb18030/)
- [gbk](src/gbk/)
- [utf8](src/utf8/)
- [utf16](src/utf16/)

## 详细文档

- [qualify](docs/qualify/readme.md)
- [qualify_multi](docs/qualify_multi/readme.md)
- [qualify_multi_test](docs/qualify_multi_test/readme.md)
- [quantify](docs/quantify/readme.md)
- [quantify_multi](docs/quantify_multi/readme.md)
- [quantify_multi_test](docs/quantify_multi_test/readme.md)
- [desc_coun](docs/desc_coun/readme.md)
- [cross_table](docs/cross_table/readme.md)
