${event.name}.hpp
/* Autogenerated with kurento-module-creator */

#ifndef __${camelToUnderscore(event.name)}_HPP__
#define __${camelToUnderscore(event.name)}_HPP__

#include <json/json.h>
#include <memory>
<#if event.extends??>
#include "${event.extends.name}.hpp"
</#if>

<#list module.code.implementation["cppNamespace"]?split("::") as namespace>
namespace ${namespace}
{
</#list>
class ${event.name};
<#list module.code.implementation["cppNamespace"]?split("::")?reverse as namespace>
} /* ${namespace} */
</#list>

namespace kurento
{
class JsonSerializer;
void Serialize (std::shared_ptr<${module.code.implementation["cppNamespace"]}::${event.name}> &object, JsonSerializer &s);
}

${organizeDependencies(typeDependencies(event),false)}
<#list module.code.implementation["cppNamespace"]?split("::") as namespace>
namespace ${namespace}
{
</#list>
<#list event.properties as property>
<#if module.remoteClasses?seq_contains(property.type.type) ||
  module.complexTypes?seq_contains(property.type.type) ||
  module.events?seq_contains(property.type.type)>
class ${property.type.name};
</#if>
</#list>

class ${event.name}<#if event.extends??> : public ${event.extends.name}</#if>
{

public:

  ${event.name} (<#rt>
    <#lt><#assign first = true><#rt>
    <#lt><#list event.parentProperties as property><#rt>
      <#lt><#if !property.name?starts_with("timestamp") && property.name != "tags"><#rt>
        <#lt><#if !property.optional><#rt>
          <#lt><#if !first>, </#if><#rt>
          <#lt><#assign first = false><#rt>
          <#lt>${getCppObjectType(property.type)}${property.name}<#rt>
        <#lt></#if><#rt>
      <#lt></#if><#rt>
    <#lt></#list><#rt>
    <#lt><#list event.properties as property><#rt>
      <#lt><#if !property.name?starts_with("timestamp") && property.name != "tags"><#rt>
        <#lt><#if !property.optional><#rt>
          <#lt><#if !first>, </#if><#rt>
          <#lt><#assign first = false><#rt>
          <#lt>${getCppObjectType(property.type)}${property.name}<#rt>
        <#lt></#if><#rt>
      <#lt></#if><#rt>
    <#lt></#list>)<#rt>
    <#lt><#assign first = true><#rt>
    <#lt><#if event.extends??> : ${event.extends.name} (<#rt>
      <#lt><#if event.name != "RaiseBase"><#rt>
        <#lt><#list event.parentProperties as property><#rt>
          <#lt><#if !property.name?starts_with("timestamp") && property.name != "tags"><#rt>
            <#lt><#if !property.optional><#rt>
              <#lt><#if !first>, </#if><#rt>
              <#lt><#assign first = false><#rt>
              <#lt>${property.name}<#rt>
            <#lt></#if><#rt>
          <#lt></#if><#rt>
      <#lt></#list>)</#if> {
      <#list event.properties as property><#rt>
        <#lt><#if !property.name?starts_with("timestamp") && property.name != "tags"><#rt>
          <#lt><#if !property.optional><#rt>
      this->${property.name} = ${property.name};
          </#if><#rt>
        </#if><#rt>
      <#lt></#list>
  }</#if>;

  ${event.name} (const ${event.name} &copy)<#rt>
    <#lt><#assign first = true><#rt>
    <#lt><#if event.extends??> : ${event.extends.name} (copy)</#if> {
      <#list event.properties as property><#rt>
        <#lt>
      this->${property.name} = copy.${property.name};
        <#lt><#if property.optional><#rt>
      this->_isSet${property.name} = copy._isSet${property.name};
        </#if><#rt>
      <#lt></#list>
  };

  ${event.name} (const Json::Value &value);

  <#if !event.extends??>virtual </#if>~${event.name}()<#if event.extends??> override</#if> = default;

  <#list event.properties as property>
  virtual void set${property.name?cap_first} (${getCppObjectType(property.type, true)}${property.name}) {
    this->${property.name} = ${property.name};
    <#if property.optional>
    _isSet${property.name?cap_first} = true;
    </#if>
  };

  virtual ${getCppObjectType(property.type)}get${property.name?cap_first} () {
    return ${property.name};
  };

  <#if property.optional>
  virtual bool isSet${property.name?cap_first} () {
    return _isSet${property.name?cap_first};
  };

  </#if>
  </#list>
  static std::string getName() {
    return "${event.name}";
  }

  <#if !event.extends??>virtual </#if>void Serialize (JsonSerializer &s)<#if event.extends??> override</#if>;

protected:

  ${event.name}() = default;

private:
  <#list event.properties as property>
  ${getCppObjectType(property.type, false)} ${property.name};
  <#if property.optional>
  bool _isSet${property.name?cap_first} = false;
  </#if>
  </#list>

  friend void kurento::Serialize (std::shared_ptr<${module.code.implementation["cppNamespace"]}::${event.name}> &event, JsonSerializer &s);
};

<#list module.code.implementation["cppNamespace"]?split("::")?reverse as namespace>
} /* ${namespace} */
</#list>

#endif /*  __${camelToUnderscore(event.name)}_HPP__ */