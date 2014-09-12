<#assign node_name=module.code.api.js.nodeName>
package.json
{
  "name": "${node_name}",
  "version": "${module.version}",
  "description": "${module.code.api.js.npmDescription}",
  "homepage": "http://www.kurento.com",
  "main": "lib/index.js",
  "author": "Kurento <info@kurento.com> (http://kurento.org)",
  "license": "LGPL",
<#if module.code.api.js.npmGit??>
  "repository": {
    "type": "git",
    "url": "${module.code.api.js.npmGit}"
  },
</#if>
  "bugs": {
    "url": "Kurento/${node_name}-js/issues",
    "email": "info@kurento.com"
  },
  "keywords": [
    "API",
    "Kurento",
    "KWS",
    "SDK",
    "web",
    "WebRTC"
  ],
  "dependencies": {
    "inherits": "^2.0.1"<#if module.imports?has_content>,
  <#list module.imports as import>
    "${import.module.code.api.js.nodeName}": "${import.npmVersion}"<#if import_has_next>,</#if>
  </#list>
</#if>
  }<#if node_name != "kurento-client-core"
     && node_name != "kurento-client-elements"
     && node_name != "kurento-client-filters">,
  "peerDependencies": {
    <#list module.imports as import><#if import.name = "core">
    "kurento-client": "${import.npmVersion}"
    </#if></#list>
  }
</#if>
}
