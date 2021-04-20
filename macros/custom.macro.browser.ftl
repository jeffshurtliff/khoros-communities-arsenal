<#-------------------------------------------------------
  Browser Fingerprinting Functions and Macros
  Created By:           Jeff Shurtliff
  Last Modified By:     Jeff Shurtliff
  Last Modified Date:   2021-04-19
-------------------------------------------------------->

<#-------------------- BEGIN MANIFEST -------------------
    Functions:
      - getBrowserInfo
      - getFingerprint
      - getOperatingSystem
---------------------- END MANIFEST -------------------->


<#-------------------- FUNCTIONS -------------------->


<#-------------------- Function: getBrowserInfo -------------------->
<#-- This function retrieves information about the browser and operating system -->
<#function getBrowserInfo userAgent='' secUserAgent=''>
  <#-- Initially define the hash to be returned -->
  <#local browserInfo = {"base": "", "specific": "", "fingerprint": "", "os": ""} />

  <#-- Get the user-agent string and fingerprint -->
  <#if userAgent?? && userAgent?has_content>
    <#local fingerprint = '' />
  <#else>
    <#local userAgent = http.request.getHeader("User-Agent")!"" />
    <#local fingerprint = getFingerprint(secUserAgent)!"" />
    <#local browserInfo += {"fingerprint": fingerprint} />
  </#if>

  <#-- Get the operating system -->
  <#local operatingSystem = getOperatingSystem(userAgent)!"" />
  <#local browserInfo += {"os": "${operatingSystem}"} />

  <#-- Attempt to first identify the browser via the fingerprint -->
  <#if fingerprint?? && fingerprint?has_content>
    <#if fingerprint?seq_contains('Google Chrome')>
      <#local browserInfo += {"base": "Chrome", "specific": "Google Chrome"} />
    <#elseif fingerprint?seq_contains('Microsoft Edge') && fingerprint?contains('Chromium')>
      <#local browserInfo += {"base": "Edge (Chromium)", "specific": "Edge (Chromium)"} />
    <#else>
      <#local otherBrowsers = ['Opera', 'Slimjet', 'Torch', 'Comodo Dragon', 'Rockmelt', 'Coolnovo', 'Yandex', 'Vivaldi', 'Chromium'] />
      <#list otherBrowsers as browser>
        <#if fingerprint?seq_contains(browser)>
          <#local browserInfo += {"base": "${browser}", "specific": "${browser}"} />
          <#break />
        </#if>
      </#list>
    </#if>
  </#if>

  <#-- Analyze the user-agent stirng if more information can be deciphered -->
  <#if (!browserInfo.base?? || !browserInfo.base?has_content) || (!browserInfo.specific?? || !browserInfo.specific?has_content)>
    <#-- Identify the browser based on operating system and/or user-agent string -->
    <#if operatingSystem?starts_with('Windows')>
      <#-- Identify Windows browsers -->
      <#if userAgent?contains('Trident/') || userAgent?contains('MSIE')>
        <#local browserInfo += {"base": "Internet Explorer", "specific": "Internet Explorer"} />
        <#-- Identify the details for the Internet Explorer browser -->
        <#if userAgent?contains('MSIE 7.0')>
          <#if userAgent?contains('Windows NT 6.0') || userAgent?contains('WOW64')>
            <#local browserInfo += {"specific": "Internet Explorer 8"} />
          <#else>
            <#local browserInfo += {"specific": "Internet Explorer 7"} />
          </#if>
        <#elseif userAgent?contains('MSIE 8.0')>
          <#local browserInfo += {"specific": "Internet Explorer 8"} />
        <#elseif userAgent?contains('MSIE 9.0')>
          <#local browserInfo += {"specific": "Internet Explorer 9"} />
        <#elseif userAgent?contains('MSIE 10.0') || userAgent?contains('Trident/6.0')>
          <#local browserInfo += {"specific": "Internet Explorer 10"} />
        <#elseif userAgent?contains('Trident/7.0') || userAgent?contains('rv:11.0')>
          <#local browserInfo += {"specific": "Internet Explorer 11"} />
        <#elseif userAgent?contains('Edge/') || userAgent?contains('Edg/')>
          <#local browserInfo += {"base": "Edge (Legacy)", "specific": "Edge (Legacy)"} />
        </#if>
      <#elseif userAgent?contains('Edge/') || userAgent?contains('Edg/')>
        <#local browserInfo += {"base": "Edge", "specific": "Edge"} />
        <#-- Identify the details for the Microsoft Edge browser -->
        <#if userAgent?contains('Edge/12.') || userAgent?contains('Edge/13.') || userAgent?contains('Edge/14.') || userAgent?contains('Edge/17.') || userAgent?contains('Edge/18.')>
          <#local browserInfo += {"specific": "Edge (Legacy)"} />
        <#elseif userAgent?contains('Edg/')>
          <#local browserInfo += {"specific": "Edge (Chromium)"} />
        </#if>
      <#elseif !userAgent?contains('like Gecko') && (userAgent?contains('Gecko/') || userAgent?contains('Firefox/'))>
        <#local browserInfo += {"base": "Firefox", "specific": "Firefox"} />
      <#elseif userAgent?contains('Vivaldi/')>
        <#local browserInfo += {"base": "Vivaldi", "specific": "Vivaldi"} />
      <#elseif userAgent?contains('OPR/')>
        <#local browserInfo += {"base": "Opera", "specific": "Opera"} />
      </#if>
    </#if>
  </#if>
  <#return browserInfo />
</#function>


<#-------------------- Function: getFingerprint -------------------->
<#-- This function retrieves and parses fingerprint data for Chromium browsers -->
<#function getFingerprint secUserAgent='' parse=true>
  <#-- Retrieve the SEC-CH-UA value if present -->
  <#if !secUserAgent?? || !secUserAgent?has_content>
    <#local secUserAgent = http.request.getHeader("SEC-CH-UA")!"" />
  </#if>

  <#-- Splice the raw value -->
  <#if secUserAgent?has_content && secUserAgent?contains(';')>
    <#local fingerprint = secUserAgent?replace('"','')?split(';')![secUserAgent] />
  <#else>
    <#local fingerprint = [secUserAgent] />
  </#if>

  <#-- Parse the raw data if desired -->
  <#if parse?? && parse>
    <#local parsed = [] />
    <#local markers = ['Chrome', 'Chromium', 'Google Chrome', 'Microsoft Edge', 'Opera', 'Slimjet', 'Torch', 'Comodo Dragon', 'Rockmelt', 'Coolnovo', 'Yandex', 'Vivaldi'] />
    <#list fingerprint as entry>
      <#list markers as marker>
        <#if entry?contains(marker)>
          <#local parsed += [marker] />
        </#if>
      </#list>
    </#list>
    <#if parsed?seq_contains('Microsoft Edge') && parsed?seq_contains('Chromium')>
      <#local parsed += ['Microsoft Edge (Chromium)'] />
    </#if>
    <#local fingerprint = parsed />
  </#if>

  <#-- Return the fingerprint sequence -->
  <#return fingerprint />
</#function>


<#-------------------- Function: getOperatingSystem -------------------->
<#-- This function identifies the operating system of the browser via the user-agent string -->
<#function getOperatingSystem userAgent=''>
  <#-- Get the user-agent string -->
  <#if !userAgent?? || !userAgent?has_content>
    <#local userAgent = http.request.getHeader('User-Agent')!'' />
  </#if>

  <#-- Identify and return the operating system by analyzing the user-agent string -->
  <#if userAgent?contains('Windows NT')>
    <#if userAgent?contains('Windows NT 5.1')>
      <#local operatingSystem = 'Windows XP' />
    <#elseif userAgent?contains('Windows NT 6.0')>
      <#local operatingSystem = 'Windows Vista' />
    <#elseif userAgent?contains('Windows NT 6.1')>
      <#local operatingSystem = 'Windows 7' />
    <#elseif userAgent?contains('Windows NT 6.2')>
      <#local operatingSystem = 'Windows 8' />
    <#elseif userAgent?contains('Windows NT 6.3')>
      <#local operatingSystem = 'Windows 8.1' />
    <#elseif userAgent?contains('Windows NT 10.0')>
      <#local operatingSystem = 'Windows 10' />
    <#else>
      <#local operatingSystem = 'Windows' />
    </#if>
  <#elseif userAgent?contains('Macintosh;')>
    <#local operatingSystem = 'macOS' />
  <#elseif userAgent?contains('iPhone;')>
    <#local operatingSystem = 'iOS' />
  <#elseif userAgent?contains('CrOS')>
    <#local operatingSystem = 'Chrome OS' />
  <#elseif userAgent?contains('Android')>
    <#local operatingSystem = 'Android' />
  <#elseif userAgent?contains('Linux;')>
    <#local operatingSystem = 'Linux' />
  <#else>
    <#local operatingSystem = 'Unknown' />
  </#if>
  <#return operatingSystem />
</#function>
