<#include "./valuables.ftl">
<#assign createPath = "${createPath_val}/${application.model}/${application.model}-web/build.gradle">

apply plugin: 'java'
apply plugin: 'groovy'
apply plugin: 'idea'
apply plugin: 'eclipse'

sourceCompatibility = 1.8
targetCompatibility = 1.8

//Need for Windows
def defaultEncoding = 'UTF-8'

repositories {
    mavenCentral()
    jcenter()
    maven {
        url "http://repository.jboss.org/nexus/content/groups/public-jboss" // JBoss
        url "http://repository.apache.org/content/groups/public"            // Apache
        url "http://repository.springsource.com/maven/bundles/release"      // SpringSource
        url "http://repository.codehaus.org"                                // Codehaus
        url "http://download.java.net/maven/2"                              // Java.NET
        url "http://download.java.net/maven/glassfish"                      // Glassfish
        url "http://m2repo.spockframework.org/snapshots"                    // Spock Snapshot
        url "http://repository.sonatype.org/content/groups/public"
        url "https://mvnrepository.com/artifact/com.sun/tools"
    }
}

task getHomeDir << {
    println gradle.gradleHomeDir
}

dependencies {
    compile 'biz.aQute.bnd:biz.aQute.bndlib:3.1.0'
    compile 'com.google.errorprone:error_prone_annotations:2.0.19'
    compile 'commons-digester:commons-digester:1.8.1'
    compile "com.google.guava:guava:21.0"
    compile "commons-io:commons-io:2.5"
    compile "commons-validator:commons-validator:1.6"
    compile "org.apache.commons:commons-lang3:3.5"
    compile group: "com.liferay", name: "com.liferay.application.list.api", version: "2.0.0"
    compile group: "com.liferay", name: "com.liferay.frontend.taglib", version: "2.0.0"
    compile group: "com.liferay", name: "com.liferay.item.selector.api", version: "2.0.0"
    compile group: "com.liferay", name: "com.liferay.item.selector.criteria.api", version: "2.0.0"
    compile group: "com.liferay", name: "com.liferay.item.selector.taglib", version: "1.0.0"
    compile group: "com.liferay", name: "com.liferay.frontend.taglib", version: "2.0.0"
    compile group: "com.liferay", name: "com.liferay.trash.taglib", version: "2.0.0"
    compile group: "com.liferay", name: "com.liferay.portal.spring.extender", version: "2.0.13"
    compile group: "com.liferay.portal", name: "com.liferay.portal.kernel", version: "2.15.0"
    compile group: "com.liferay.portal", name: "com.liferay.portal.impl", version: "2.15.0"
    compile group: "com.liferay.portal", name: "com.liferay.util.taglib", version: "2.8.0"
    compile group: "javax.portlet", name: "portlet-api", version: "2.0"
    compile group: "javax.servlet", name: "javax.servlet-api", version: "3.0.1"
    compile group: "jstl", name: "jstl", version: "1.2"
    compile group: "org.osgi", name: "osgi.cmpn", version: "6.0.0"
    compile group: "org.osgi", name: "org.osgi.service.component.annotations", version: "1.3.0"

    compileOnly project(":${capFirstModel}-api")
    compileOnly project(":${capFirstModel}-service")
}