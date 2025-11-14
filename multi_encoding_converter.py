from pathlib import Path


if __name__ == "__main__":
    # 以 gbk 编码格式为基准
    base_encode = "gbk"

    # 转换编码格式列表
    convert_encode_list = ["utf8", "gb2312", "gb18030"]

    # 开始转换
    base_path = Path("src") / base_encode
    base_files = {file.name for file in base_path.glob("*.sas")}
    
    for convert_encode in convert_encode_list:
        convert_path = Path("src") / convert_encode
        if not convert_path.exists():
            convert_path.mkdir(parents=True)
        
        # 删除 base_path 中已不存在的文件
        for file in convert_path.glob("*.sas"):
            if file.name not in base_files:
                file.unlink()
        
        # 复制或更新 base_path 中的文件
        for file in base_path.glob("*.sas"):
            content = file.read_text(encoding=base_encode)
            (Path(convert_path) / file.name).write_text(content, encoding=convert_encode)
