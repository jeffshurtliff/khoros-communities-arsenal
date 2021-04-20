<#----------------------------------------------------
  Functions and Macros for Logging and Debugging
  Created By:           Jeff Shurtliff
  Last Modified By:     Jeff Shurtliff
  Last Modified Date:   2021-04-20
----------------------------------------------------->

<#-------------------- BEGIN MANIFEST ----------------
    Functions:
    - executedByEndpoint
    Macros:
    - consoleDebug
    - consoleError
    - consoleInfo
    - consoleLog
    - consoleWarn
    - recordStackTrace
---------------------- END MANIFEST ----------------->

<#------------- Define Debug Mode Status------------->
<#global PROD_DEBUG_MODE = false />
<#global STAGE_DEBUG_MODE = true />


<#-------------------- FUNCTIONS -------------------->


<#-------------------- Function: executedByEndpoint -------------------->
<#-- This function checks to see if the parent macro is being called from a custom endpoint -->
<#function executedByEndpoint>
  <#local isEndpoint = false />
  <#if http.request.url?contains('/plugins/custom/')>
    <#local isEndpoint = true />
  </#if>
  <#return isEndpoint>
</#function>


<#---------------------- MACROS --------------------->


<#-------------------- Macro: consoleDebug -------------------->
<#-- This macro prints a debug message to the browser JavaScript console (i.e. console.debug) -->
<#macro consoleDebug logEntry="">
  <#if !executedByEndpoint()>
    <#local environment = config.getString("phase", "prod") />
    <#if (environment == "prod" && PROD_DEBUG_MODE) || (environment == "stage" && STAGE_DEBUG_MODE)>
      <@liaAddScript>
        ; (function ($) {
          console.debug("${logEntry}");
        })(LITHIUM.jQuery);
      </@liaAddScript>
    </#if>
  </#if>
</#macro>


<#-------------------- Macro: consoleError -------------------->
<#-- This macro prints an error to the browser JavaScript console (i.e. console.error) -->
<#macro consoleError logEntry="">
  <#if !executedByEndpoint()>
    <@liaAddScript>
      ; (function ($) {
        console.error("${logEntry}");
      })(LITHIUM.jQuery);
    </@liaAddScript>
  </#if>
</#macro>


<#-------------------- Macro: consoleInfo -------------------->
<#-- This macro prints an info message to the browser JavaScript console (i.e. console.info) -->
<#macro consoleInfo logEntry="">
  <#if !executedByEndpoint()>
    <@liaAddScript>
      ; (function ($) {
        console.info("${logEntry}");
      })(LITHIUM.jQuery);
    </@liaAddScript>
  </#if>
</#macro>


<#-------------------- Macro: consoleLog -------------------->
<#-- This macro prints an entry to the browser JavaScript console (i.e. console.log) -->
<#macro consoleLog logEntry="">
  <#if !executedByEndpoint()>
    <@liaAddScript>
      ; (function ($) {
        console.log("${logEntry}");
      })(LITHIUM.jQuery);
    </@liaAddScript>
  </#if>
</#macro>


<#-------------------- Macro: consoleWarn -------------------->
<#-- This macro prints a warning message to the browser JavaScript console (i.e. console.warn) -->
<#macro consoleWarn logEntry="">
  <#if !executedByEndpoint()>
    <@liaAddScript>
      ; (function ($) {
        console.warn("${logEntry}");
      })(LITHIUM.jQuery);
    </@liaAddScript>
  </#if>
</#macro>


<#-------------------- Macro: recordStackTrace -------------------->
<#-- This macro captures the stack trace in a global variable for a failure inside an attempt/recover block -->
<#macro recordStackTrace json=true>
  <#if .error?? && .error?has_content>
    <#if json>
      <#global stackTrace = .error?json_string />
    <#else>
      <#global stackTrace = .error />
    </#if>
  </#if>
</#macro>

