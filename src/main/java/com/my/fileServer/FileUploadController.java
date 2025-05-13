package com.my.fileServer;

import com.my.fileServer.dto.FileDTO;
import com.my.fileServer.storage.StorageFileNotFoundException;
import com.my.fileServer.storage.StorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Controller
public class FileUploadController {

    private final StorageService storageService;

    @Autowired
    public FileUploadController(StorageService storageService) {
        this.storageService = storageService;
    }

    @GetMapping("/")
    public String listUploadFiles(Model model) throws IOException {

//        model.addAttribute("files", storageService.loadAll().map(
//                path -> MvcUriComponentsBuilder.fromMethodName(
//                        FileUploadController.class,
//                        "saveFile",
//                        path.getFileName().toString()).build().toUri().toString())
//                .collect(Collectors.toList()));
        List<FileDTO> fileDTOList = storageService.loadAllFiles();
        model.addAttribute("files", fileDTOList);

        return "uploadForm";
    }

    //list files with csv format
    @GetMapping("/list-csv")
    @ResponseBody
    public String listFiles() {
        List<FileDTO> fileDTOList = storageService.loadAllFiles();
        StringBuilder csvSb = new StringBuilder();
        for ( FileDTO fileDTO : fileDTOList ) {
            csvSb.append(fileDTO.getFileName()).append(",")
                    .append(fileDTO.getFileSize()).append(",")
                    .append(fileDTO.getFileTime()).append(",")
                    .append(fileDTO.getDownloadUri()).append("\n");
        }
        return csvSb.toString();
    }

    //list files with json format
    @GetMapping("/list-json")
    @ResponseBody
    public ResponseEntity<List<FileDTO>> listFilesJson() {
        List<FileDTO> fileDTOList = storageService.loadAllFiles();
        return ResponseEntity.ok(fileDTOList);
    }

    @GetMapping("/files/{filename:.+}")
    @ResponseBody
    public ResponseEntity<Resource> saveFile(@PathVariable String filename) {
        Resource file = storageService.loadAsResource(filename);
        return ResponseEntity.ok().header(
                HttpHeaders.CONTENT_DISPOSITION,
                "attachment; filename=\"" + filename + "\"").body(file);
    }

    @PostMapping("/")
    public String handleFileUpload(@RequestParam("file") MultipartFile file,
                                   RedirectAttributes redirectAttributes) {

        String message = storageService.storeFile(file);
        redirectAttributes.addFlashAttribute("message", message);

        return "redirect:/";
    }

    @ExceptionHandler(StorageFileNotFoundException.class)
    public ResponseEntity<?> handleStorageFileNotFound(StorageFileNotFoundException exec) {
        return ResponseEntity.notFound().build();
    }
}
