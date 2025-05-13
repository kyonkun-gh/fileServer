package com.my.fileServer.storage;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("storage")
public class StorageProperties {

    /**
     * Folder location for storing files
     */
    private String location = "upload-dir";

    private String tmpLocation = "upload-tmp";

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getTmpLocation() { return tmpLocation; }

    public void setTmpLocation(String tmpLocation) { this.tmpLocation = tmpLocation; }
}
