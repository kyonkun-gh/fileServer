package com.my.fileServer;

import org.springframework.stereotype.Component;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

@Component
public class MyFilter /*implements Filter*/ {
//    @Override
    public void doFilter(ServletRequest servletRequest,
                         ServletResponse servletResponse,
                         FilterChain filterChain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) servletRequest;
        HttpServletResponse res = (HttpServletResponse) servletResponse;

        Path path = Paths.get(req.getRequestURI());
        HttpServletRequestWrapper wrapper = new HttpServletRequestWrapper(req) {
//            @Override
//            public StringBuffer getRequestURL() {
//                StringBuffer sb = ((HttpServletRequest) getRequest()).getRequestURL();
//                System.out.println("sb is: " + sb.toString());
//                Path path = Paths.get(sb.toString());
//                System.out.println("Wrapper URI is: " + path.normalize());
//                return new StringBuffer( path.normalize().toString() );
//            }
            @Override
            public String getRequestURI() {
                return "";
            }
        };

        System.out.println("Request URI is: " + req.getRequestURL());
        System.out.println("Wrapper URI is: " + wrapper.getRequestURI());
        System.out.println("Wrapper URL is: " + wrapper.getRequestURL());
//        filterChain.doFilter(servletRequest, servletResponse);
        filterChain.doFilter(wrapper, servletResponse);
        System.out.println("Response Status Code is: " + res.getStatus());
    }
}
