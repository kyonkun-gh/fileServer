package com.my.fileServer.storage;

import com.my.fileServer.dto.FileDTO;
import org.springframework.core.io.Resource;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Path;
import java.util.List;
import java.util.stream.Stream;

public interface StorageService {

    void init();

    String storeFile(MultipartFile file);

    Stream<Path> loadAll();
    List<FileDTO> loadAllFiles();

    Path load(String filename);

    Resource loadAsResource(String filename);

    void deleteAll();
}
