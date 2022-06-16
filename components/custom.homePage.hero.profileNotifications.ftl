<#----------------------------------------------
  Profile Notifications
  ----------------------------------------------
  Scope:                  Home Page Hero
  Instance:               Shared
  Created By:             Jeff Shurtliff
  Last Modified By:       Jeff Shurtliff
  Last Modified Date:     2021-12-16
  Last Reviewed By:       N/A
  Last Reviewed Date:     N/A
------------------------------------------------>

<#-- Reference: theme-lib.profile-notifications.ftl (Hermes) -->
<#-- TODO: Figure out if all of the integer conversions are even necessary -->

<#-- Import dependencies -->
<#import 'custom.macro.logging' as logging />
<#import 'custom.macro.common.utils' as commonUtils />
<#import 'custom.macro.common.notifications' as notificationUtils />

<#-- Initialize logging -->
<@logging.init 'custom.homePage.hero.profileNotifications' />
<@logging.setLogName 'home-page' />

<#attempt>
  <#-- Define the parameters -->
  <#assign notificationCount = commonUtils.getParameter('numberOfNotifications', '5', 'component') />
  <#assign notificationCount = commonUtils.ensureNumber(notificationCount) />
  <#assign showTitle = commonUtils.getParameter('showTitle', 'true', 'component', true)!true />
  <#assign userId = commonUtils.getParameter('userId', '', 'component') />
  <#assign currentUser = userId />
  <#if page.name == 'ViewProfilePage' >
    <#assign currentUser = page.context.user.id />
    <@logging.verbose "Using the context user ID as a profile is being viewed rather than the home page." />
  </#if>
  <#assign currentUser = commonUtils.ensureNumber(currentUser) />
  
  <#-- Identify the notifications data -->
  <#if !user.anonymous && currentUser?has_content && currentUser == commonUtils.ensureNumber(user.id)>
    <#assign response = rest('/users/self/notifications') />
    <#if (response.notifications.notification)??>
      <#assign notificationData = [] />
      <#assign count = 0 />
      <#list response.notifications.notification as notification>
        <#assign currentData = notificationUtils.getNotificationData(notification) />
        <#if currentData?? && currentData?has_content>
          <#assign notificationData += [currentData] />
          <#assign count += 1 />
        </#if>
        
        <#-- Stop looping through the notification data if the maximum count has been reached -->
        <#if count == commonUtils.ensureNumber(notificationCount)>
          <#break />
        </#if>
      </#list>
      <#assign title = '' />
      <#if showTitle?is_boolean && showTitle>
        <#assign title = text.format('theme-lib.profile-notifications.title') />
      </#if>

      <#-- Render the component -->
      <div class="custom-profile-notifications  ${CSS_NAMESPACE}-c-profile-notifications">
        <section>
          <#if showTitle?is_boolean && showTitle>
            <h2>${title}</h2>
          </#if>
          <#if notificationData?? && notificationData?has_content>
            <ul>
              <#list notificationData as currentNotificationData>
                <li>
                  <@notificationUtils.displayNotification currentNotificationData />
                </li>
              </#list>
            </ul>
            
            <#-- Render the View All link if on the home page -->
            <#if page.name != "CommunityPage">
              <div class="lia-view-all  ${CSS_NAMESPACE}-c-profile-notifications__view-all">
                <a class="view-all-link" href="${webuisupport.urls.page.name.get('NotificationFeedPage').build()}">${text.format('general.View_All')}</a>
              </div>
            </#if>
          </#if>
        </section>
      </div>
    </#if>
  <#else>
    <@logging.error "A user mismatch was detected when rendering the home page notification section." />
  </#if>
<#recover>
  <@logging.error "Encountered an exception while rendering the profile notifications section for ${(user.login)!'UNKNOWN_USERNAME'}." />
  <@logging.exception .error true />
</#attempt>

