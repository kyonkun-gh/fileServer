package com.my.fileServer;

import org.apache.catalina.connector.Connector;
import org.bouncycastle.asn1.x500.X500Name;
import org.bouncycastle.asn1.x509.*;
import org.bouncycastle.cert.X509CertificateHolder;
import org.bouncycastle.cert.jcajce.JcaX509CertificateConverter;
import org.bouncycastle.cert.jcajce.JcaX509v3CertificateBuilder;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.operator.ContentSigner;
import org.bouncycastle.operator.jcajce.JcaContentSignerBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory;
import org.springframework.boot.web.server.Ssl;
import org.springframework.boot.web.server.SslStoreProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.math.BigInteger;
import java.security.*;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import java.util.Date;


@Configuration
public class InMemorySelfSignedCertConfig {

    @Value("${server.port:8443}")
    private int serverPort;
    @Value("${server.http.port:-1}")
    private int serverHttpPort;
    @Value("${server.ssl.key-alias}")
    private String keyAlias;
    @Value("${server.ssl.key-password}")
    private String keyPassword;
    @Value("${server.ssl.key-store-type}")
    private String keyStoreType;

    @Bean
    public static BouncyCastleProvider bcProvider() {
        BouncyCastleProvider provider = new BouncyCastleProvider();
        if (Security.getProvider(provider.getName()) == null) {
            Security.addProvider(provider);
        }
        return provider;
    }

    @Bean
    public SslStoreProvider sslStoreProvider(BouncyCastleProvider bcProvider) throws Exception {
        // Generate key pair
        KeyPairGenerator keyGen = KeyPairGenerator.getInstance("RSA", "BC");
        keyGen.initialize(2048);
        KeyPair keyPair = keyGen.generateKeyPair();

        // Generate self-signed certificate
        X500Name issuer = new X500Name("CN=localhost");
        BigInteger serial = new BigInteger(64, new SecureRandom());
        Date notBefore = new Date(System.currentTimeMillis() - 60_000L);
        Date notAfter = new Date(System.currentTimeMillis() + 365L * 24 * 60 * 60 * 1000); // 1 年
        X500Name subject = new X500Name("CN=localhost");

        JcaX509v3CertificateBuilder certificateBuilder = new JcaX509v3CertificateBuilder(
                issuer, serial, notBefore, notAfter, subject, keyPair.getPublic());

        certificateBuilder.addExtension(Extension.basicConstraints, true, new BasicConstraints(false));

        KeyUsage keyUsage = new KeyUsage(KeyUsage.digitalSignature | KeyUsage.keyEncipherment);
        certificateBuilder.addExtension(Extension.keyUsage, true, keyUsage);

        ExtendedKeyUsage extendedKeyUsage = new ExtendedKeyUsage(KeyPurposeId.id_kp_serverAuth);
        certificateBuilder.addExtension(Extension.extendedKeyUsage, false, extendedKeyUsage);

        GeneralName dns = new GeneralName(GeneralName.dNSName, "localhost");
        GeneralName ip = new GeneralName(GeneralName.iPAddress, "127.0.0.1");
        GeneralNames sans = new GeneralNames(new GeneralName[]{dns, ip});
        certificateBuilder.addExtension(Extension.subjectAlternativeName, false, sans);

        ContentSigner signer = new JcaContentSignerBuilder("SHA256withRSA")
                .setProvider(bcProvider).build(keyPair.getPrivate());

        X509CertificateHolder holder = certificateBuilder.build(signer);
        X509Certificate cert = new JcaX509CertificateConverter()
                .setProvider(bcProvider).getCertificate(holder);

        cert.verify(keyPair.getPublic(), bcProvider);

        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        keyStore.load(null, null);
        keyStore.setKeyEntry(keyAlias, keyPair.getPrivate(), keyPassword.toCharArray(), new Certificate[]{cert});

        return new SslStoreProvider() {
            @Override
            public KeyStore getKeyStore() throws Exception {
                return keyStore; // 私鑰 + 憑證鏈（此處只有自簽）
            }
            @Override
            public KeyStore getTrustStore() throws Exception {
                return null; // 若需雙向 TLS 或自訂信任庫，可在此提供
            }
        };
    }

    @Bean
    public TomcatServletWebServerFactory tomcatFactory(SslStoreProvider sslStoreProvider) throws Exception {
        TomcatServletWebServerFactory tomcat = new TomcatServletWebServerFactory() {
            @Override
            protected void postProcessContext(org.apache.catalina.Context context) {
                // ...existing code...
            }
        };

        tomcat.setPort(serverPort);
        tomcat.setSsl(createSsl());
        tomcat.setSslStoreProvider(sslStoreProvider);

        // 只有 serverHttpPort > 0 時才啟動 HTTP connector
        if (serverHttpPort > 0) {
            tomcat.addAdditionalTomcatConnectors(createStandardConnector());
        }

        return tomcat;
    }

    private Ssl createSsl() {
        Ssl ssl = new Ssl();
        ssl.setEnabled(true);
        ssl.setKeyAlias(keyAlias);
        ssl.setKeyPassword(keyPassword);
        ssl.setKeyStoreType(keyStoreType);
        return ssl;
    }

    private Connector createStandardConnector() {
        Connector connector = new Connector(org.apache.coyote.http11.Http11NioProtocol.class.getName());
        connector.setPort(serverHttpPort);
        return connector;
    }
}
