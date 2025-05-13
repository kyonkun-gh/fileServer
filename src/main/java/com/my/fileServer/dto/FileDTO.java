package com.my.fileServer.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Data;

import java.nio.file.attribute.FileTime;

@Data
public class FileDTO {
    
    private String fileName;

    @JsonIgnore
    private long size;

    private String fileSize;

    @JsonIgnore
    private FileTime lastModifiedTime;

    private String fileTime;

    private String downloadUri;
}
