package com.my.fileServer.storage;

import com.my.fileServer.FileUploadController;
import com.my.fileServer.dto.FileDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.FileSystemUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.MvcUriComponentsBuilder;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.nio.file.attribute.FileTime;
import java.text.DecimalFormat;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
public class FileSystemStorageService implements StorageService {

    private final Path rootLocation;

    private final Path rootTmpLocation;

    private static final String[] units =
            new String[]{" Bytes", " KB", " MB", " GB", " TB"};

    private static final DecimalFormat decimalformat =
            new DecimalFormat("#,##0.00");

    private static final DateTimeFormatter dateTimeformatter =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Autowired
    public FileSystemStorageService(StorageProperties properties) {
        this.rootLocation = Paths.get(properties.getLocation());
        this.rootTmpLocation = Paths.get(properties.getTmpLocation());
    }

    @Override
    public void init() {
        try {
            Files.createDirectories(rootLocation);
//            Files.createDirectories(rootTmpLocation);
//            Files.createTempDirectory(rootTmpLocation, "tmpDirPrefix");
        } catch (IOException e) {
            throw new StorageException("Could not initialize storage", e);
        }
    }

    @Override
    public String storeFile(MultipartFile file) {
        String message = "";

        try {
            if ( file.isEmpty() ) {
                message = "Failed to store empty file.";
                throw new StorageException(message);
            }

            // IE加入信任網站情況下，file.getOriginalFilename()會取得完整檔案路徑
            Path filePath = Paths.get(file.getOriginalFilename());
            Path destinationFile = this.rootLocation.resolve(filePath.getFileName())
                    .normalize().toAbsolutePath();

            if ( !destinationFile.getParent().equals( this.rootLocation.toAbsolutePath() ) ) {
                // This is a security check
                message = "Cannot store file outside current directory.";
                throw new StorageException(message);
            }

            try ( InputStream inputStream = file.getInputStream() ) {
                Files.copy(inputStream, destinationFile, StandardCopyOption.REPLACE_EXISTING);
            }

            message = "You successfully uploaded " + file.getOriginalFilename() + "!";
        } catch (IOException e) {
            message = "Failed to store file.";
            throw new StorageException(message, e);
        }

        return message;
    }

    @Override
    public Stream<Path> loadAll() {
        try {
            return Files.walk(this.rootLocation, 1)
                    .filter(path -> !path.equals(this.rootLocation))
                    .map(this.rootLocation::relativize);
        } catch (IOException e) {
            throw new StorageException("Failed to read stored files.", e);
        }
    }

    @Override
    public List<FileDTO> loadAllFiles() {
        try {
            List<Path> pathList = Files.walk(this.rootLocation, 1)
                    .filter(path -> !path.equals(this.rootLocation))
                    .collect(Collectors.toList());

            List<FileDTO> fileDTOList = new ArrayList<>();
            for ( Path path : pathList ) {
                FileDTO fileDTO = new FileDTO();
                BasicFileAttributes basicFileAttributes = Files.readAttributes(path, BasicFileAttributes.class);
                if ( basicFileAttributes.isDirectory() ) {
                    continue;
                }

                fileDTO.setFileName( path.getFileName().toString() );

                String downloadUri = MvcUriComponentsBuilder
                        .fromMethodName(FileUploadController.class, "saveFile", fileNameEncode(fileDTO.getFileName()))
                        .build().toUri().toString();
                fileDTO.setDownloadUri( downloadUri );
                fileDTO.setSize( basicFileAttributes.size() );
                fileDTO.setFileSize( toFileSizeString(fileDTO.getSize()) );
                fileDTO.setLastModifiedTime( basicFileAttributes.lastModifiedTime() );
                fileDTO.setFileTime( toLocalTimeString(fileDTO.getLastModifiedTime()) );
                fileDTOList.add( fileDTO );

//                System.out.println( fileDTO.toString() );
            }

            return fileDTOList;
        } catch (IOException e) {
            throw new StorageException("Failed to read stored files.", e);
        }
    }

    @Override
    public Path load(String filename) {
        return rootLocation.resolve(filename);
    }

    @Override
    public Resource loadAsResource(String filename) {
        try {
            filename = fileNameDecode(filename);
            Path file = load(filename);
            if ( Files.isDirectory(file) ) {
                throw new StorageException("Cannot read directory: " + filename);
            }

            Resource resource = new UrlResource(file.toUri());

            if ( resource.exists() || resource.isReadable() ) {
                return resource;
            } else {
                throw new StorageException("Could not read file: " + filename);
            }
        } catch (MalformedURLException e) {
            throw new StorageException("Could not read file: " + filename, e);
        }
    }

    @Override
    public void deleteAll() {
        FileSystemUtils.deleteRecursively(rootLocation.toFile());
    }

    private String toFileSizeString(long size) {
        int n = units.length;
        int idx = 1;
        double fileSize = size;
        while ( fileSize >= 1000 && idx < n ) {
            fileSize /= 1024;
            idx++;
        }

        return decimalformat.format(fileSize) + units[idx-1];
    }

    private String toLocalTimeString(FileTime time) {
        return LocalDateTime.ofInstant(time.toInstant(), ZoneId.systemDefault()).format(dateTimeformatter);
    }

    private String fileNameEncode(String name) {
        return URLEncoder.encode(name, StandardCharsets.UTF_8).replace("+", "%20");
    }

    private String fileNameDecode(String name) {
        return URLDecoder.decode(name, StandardCharsets.UTF_8);
    }
}
