<#-------------------------------------------------------
  Notification Functions and Macros
  -------------------------------------------------------
  Scope:                  Global
  Instance:               Shared
  Created By:             Jeff Shurtliff
  Last Modified By:       Jeff Shurtliff
  Last Modified Date:     2021-12-16
  Last Reviewed By:       N/A
  Last Reviewed Date:     N/A
-------------------------------------------------------->

<#-------------------- BEGIN MANIFEST -------------------
    Functions:
      - getAuthor
      - getNotificationData
      - hasV2EntityResults
    Macros:
      - displayItem
      - displayNotification
---------------------- END MANIFEST -------------------->

<#-- Reference: theme-lib.notification-macros.ftl (Hermes) -->

<#---------------- Import Dependencies ----------------->
<#import 'custom.macro.common.utils' as commonUtils />
<#import 'custom.macro.logging' as logging />

<#-- Initialize logging -->
<@logging.init />
<@logging.setLogName 'home-page' />


<#-------------------- FUNCTIONS -------------------->


<#-------------------- Function: getAuthor -------------------->
<#-- This function retrieves API user data for a specific author -->
<#function getAuthor userId>
  <#local results = {} />
  <#attempt>
    <#if userId?has_content>
      <#if !userId?is_string>
        <#local userId = userId?c />
      </#if>
      <#local author = rest(API_VERSION, "/users/${userId}") />
      <#if hasV2EntityResults(author)>
        <#local results = (author.data)!{}>
      <#else>
        <@logging.warning "Did not find API v2 data in the author query results for the notification." />
      </#if>
    <#else>
      <@logging.verbose "The notification being processed did not have an associated user." />
    </#if>
  <#recover>
    <@logging.error "Encountered an exception while retrieving the author info for the latest notification." />
    <@logging.exception .error />
  </#attempt>

  <#-- Log a warning if there is no content in the data hash -->
  <#if !results?has_content>
    <@logging.warning "No API user data was retrieved for the latest notification." />
  </#if>
  <#return results />
</#function>


<#-------------------- Function: getNotificationData -------------------->
<#-- This function retrieves data for a given notification -->
<#function getNotificationData notification>
  <#-- Initially define the data hash -->
  <#local results = {} />

  <#attempt>
    <#-- Define the author info -->
    <#local actorId = (notification.target.actor.id)!'' />
    <#local author = getAuthor(actorId) />
    <#local iconUrl = (author.avatar.message)!'' />
    <#local authorUrl = (author.view_href)!'' />

    <#-- If this is a rank notification then author is current user -->
    <#if notification.target.@type == "rank" || notification.target.@type == "badge">
      <@logging.verbose "The notification being examined is relating to a rank or badge." />
      <#local author = getAuthor(user.id) />
      <#local authorUrl = (author.view_href)!'' />
      <#local iconUrl = (author.avatar.message)!'' />

      <#-- Populate the data hash -->
      <#local results = {
        "iconURL": iconUrl, 
        "author.view_href": authorUrl, 
        "author.login": (author.login)!'',
        "entity": {}, 
        "type": notification.notification_type, 
        "date": "" 
      } />
    <#elseif (notification.target.entity)?? && notification.target.entity?has_content && (notification.target.entity.subject)?? && (((notification.target.entity.@view_href)?? && notification.target.entity.@view_href?has_content) || notification.target.@type == "rank")>
      <@logging.verbose "The notification being examined is not associated with a rank or badge." />
      <#-- Populate the data hash -->
      <#local results = {
        "iconURL": iconUrl, 
        "author.view_href": authorUrl, 
        "author.login": (author.login)!'', 
        "entity": notification.target.entity, 
        "type": notification.notification_type, 
        "date": notification.target.time_stamp 
      } />
    </#if>
  <#recover>
    <@logging.error "Encountered an exception while attempting to retrieve notification data." />
    <@logging.exception .error />
  </#attempt>
  <#return results />
</#function>


<#-------------------- Function: hasV2EntityResults -------------------->
<#-- This function checks to see if any v2 entity results are present -->
<#function hasV2EntityResults results>
  <#return results?has_content && results.status?? && results.status == "success" && results.data?has_content />
</#function>


<#-------------------- MACROS -------------------->


<#-------------------- Macro: displayItem -------------------->
<#-- Renders a single notification item from the notification feed -->
<#macro displayItem iconURL description date>
  <#-- TODO: See if the Icon URL should be leveraged at all here -->
  <#-- TODO: See if the no_esc built-in should be replaced with #noautoesc directive -->
  ${description?no_esc}
  <#if date?has_content>
    <time>${date}</time>
  </#if>
</#macro>


<#-------------------- Macro: displayNotification -------------------->
<#-- Display a single notification and build the suitable description depending on the type -->
<#macro displayNotification notification>
  <#-- Construct the description -->
  <#local description = '' />
  <#attempt>
    <#switch notification.type>
      <#case "mentions">
        <#local description = text.format("notificationFeed.description.mentions.text","<a href='${notification['author.view_href']}'>${notification['author.login']}</a>","<a href='${notification.entity.@view_href}'>${notification.entity.subject}</a>") />
        <#break />
      <#case "kudos">
        <#local description = text.format("notificationFeed.description.kudos.text","<a href='${notification['author.view_href']}'>${notification['author.login']}</a>", "<a href='${notification.entity.@view_href}'>${notification.entity.subject}</a>") />
        <#break/>
      <#case "topic">
        <#local description = "<a href='${notification['author.view_href']}'>${notification['author.login']}</a>&nbsp;" + text.format("notificationFeed.description.topic.reply.text") + "&nbsp;" + "<a href='${notification.entity.@view_href}'>${notification.entity.subject}</a>" />
        <#break />
      <#case "board">
        <#local description = "<a href='${notification['author.view_href']}'>${notification['author.login']}</a>&nbsp;" + text.format("notificationFeed.description.topic.reply.text") + "&nbsp;" + "<a href='${notification.entity.@view_href}'>${notification.entity.subject}</a>" />
        <#break />
      <#case "solutions">
        <#local description = text.format("notificationFeed.description.solution.text","<a href='${notification['author.view_href']}'>${notification['author.login']}</a>","<a href='${notification.entity.@view_href}'>${notification.entity.subject}</a>") />
        <#break />
      <#case "rank">
        <#local description = text.format("notificationFeed.description.rank.text","<a href='${notification['author.view_href']}'>${notification.entity.name}</a>") />
        <#break />
      <#case "badge">
        <#local description = text.format("notification_summary.notifications.newBadge.text","/t5/badges/userbadgespage/user-id/${user.id}") />
        <#break />
    </#switch>
  <#recover>
    <@logging.error "Encountered an exception while defining a notification description." />
    <@logging.exception .error />
  </#attempt>

  <#-- Construct the datestamp -->
  <#local date = '' />
  <#attempt>
  <#if notification.date?has_content>
    <#if settings.name.get("layout.friendly_dates_enabled", "false") == "true" && notification.date.@view_friendly_date?has_content>
      <#local date = notification.date.@view_friendly_date />
    <#else>
      <#local tmp = datesupport.setDate(datesupport.parseAsIso8601(notification.date?string)) />
      <#local date = tmp.getDateAsString() + " " + tmp.timeAsString />
    </#if>
  </#if>
  <#recover>
    <@logging.error "Encountered an exception while constructing the datestamp for a notification." />
    <@logging.exception .error />
  </#attempt>

  <#if description?has_content>
    <@displayItem iconURL=notification.iconURL description=description date=date />
  </#if>
</#macro>

