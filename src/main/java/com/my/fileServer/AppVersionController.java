package com.my.fileServer;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class AppVersionController {

    @Value("${app.version}")
    private String appVersion;

    @GetMapping("/version")
    @ResponseBody
    public String version() {
        return "File Server Version: " + appVersion;
    }
}
