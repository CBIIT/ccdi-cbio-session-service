package org.cbioportal.session_service.web;

import org.springframework.web.bind.annotation.*;

/**
 * @author Hongxin Zhang
 */
@RestController
@RequestMapping(value = "/info")
public class InfoController {

    public String getVersion() {
        // Read from environment variable, fallback to implementation version
        String envVersion = System.getenv("APP_VERSION");
        if (envVersion != null && !envVersion.trim().isBlank()) {
            return envVersion;
        }
        return getClass().getPackage().getImplementationVersion();
    }

    @RequestMapping(method = RequestMethod.GET, value = "")
    public String getInfo() {
        return this.getVersion();
    }
}
