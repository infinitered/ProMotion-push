module ProMotion
  # @requires class:PushNotification
  module DelegateNotifications

    attr_accessor :aps_notification

    def check_for_push_notification(options)
      if options && options[UIApplicationLaunchOptionsRemoteNotificationKey]
        received_push_notification options[UIApplicationLaunchOptionsRemoteNotificationKey], true
      end
    end

    def register_push_notification_category(category_name, actions, options = {})
      return unless actionable_notifications?

      @push_notification_categories ||= []
      UIMutableUserNotificationCategory.new.tap do |category|
        minimal = options[:minimal]
        category.setActions(minimal, forContext: UIUserNotificationActionContextMinimal) if minimal
        category.setActions(actions, forContext: UIUserNotificationActionContextDefault)
        category.identifier = category_name
        @push_notification_categories << category
      end
    end

    def register_for_push_notifications(*notification_types)
      notification_types = Array.new(notification_types)
      notification_types = [ :badge, :sound, :alert, :newsstand ] if notification_types.include?(:all)

      types = UIRemoteNotificationTypeNone
      notification_types.each { |t| types = types | map_notification_symbol(t) }

      register_for_push_notification_types(types)
    end

    def register_for_push_notification_types(types)
      UIApplication.sharedApplication.tap do |application|
        if actionable_notifications?
          settings = UIUserNotificationSettings.settingsForTypes(types, categories: @push_notification_categories)
          application.registerUserNotificationSettings settings
          application.registerForRemoteNotifications
        else
          application.registerForRemoteNotificationTypes types
        end
      end
    end

    def actionable_notifications?
      UIApplication.sharedApplication.respond_to?(:registerUserNotificationSettings)
    end

    def unregister_for_push_notifications
      UIApplication.sharedApplication.unregisterForRemoteNotifications
    end

    def registered_push_notifications
      types = []
      if UIApplication.sharedApplication.respond_to?(:currentUserNotificationSettings)
        mask = UIApplication.sharedApplication.currentUserNotificationSettings.types
      else
        mask = UIApplication.sharedApplication.enabledRemoteNotificationTypes
      end

      types << :badge     if mask & UIRemoteNotificationTypeBadge > 0
      types << :sound     if mask & UIRemoteNotificationTypeSound > 0
      types << :alert     if mask & UIRemoteNotificationTypeAlert > 0
      types << :newsstand if mask & UIRemoteNotificationTypeNewsstandContentAvailability > 0

      types
    end

    def received_push_notification_with_action(notification, action)
      @aps_notification = ProMotion::PushNotification.new(notification)
      on_push_notification_action(action, @aps_notification) if respond_to?(:on_push_notification_action)
    end

    def received_push_notification(notification, was_launched)
      @aps_notification = ProMotion::PushNotification.new(notification)
      on_push_notification(@aps_notification, was_launched) if respond_to?(:on_push_notification)
    end

    # CocoaTouch

    def application(application, didRegisterForRemoteNotificationsWithDeviceToken: device_token)
      on_push_registration(device_token, nil) if respond_to?(:on_push_registration)
    end

    def application(application, didFailToRegisterForRemoteNotificationsWithError: error)
      on_push_registration(nil, error) if respond_to?(:on_push_registration)
    end

    def application(application, didReceiveRemoteNotification: notification)
      received_push_notification(notification, application.applicationState != UIApplicationStateActive)
    end

    def application(application, didReceiveRemoteNotification: notification, fetchCompletionHandler: callback)
      result = received_push_notification(notification, application.applicationState == UIApplicationStateInactive)
      callback.call(background_fetch_result(result))
    end

    def application(application, handleActionWithIdentifier: action_identifier, forRemoteNotification: notification, completionHandler: callback)
      received_push_notification_with_action(notification, action_identifier)
      callback.call
    end

    protected

    def map_notification_symbol(symbol)
      {
        none:       UIRemoteNotificationTypeNone,
        badge:      UIRemoteNotificationTypeBadge,
        sound:      UIRemoteNotificationTypeSound,
        alert:      UIRemoteNotificationTypeAlert,
        newsstand:  UIRemoteNotificationTypeNewsstandContentAvailability
      }[symbol] || UIRemoteNotificationTypeNone
    end

    def background_fetch_result(result)
      options = {
        new_data: UIBackgroundFetchResultNewData,
        no_data: UIBackgroundFetchResultNoData,
        failed: UIBackgroundFetchResultFailed
      }
      return options[result] if options[result]

      return result if options.values.include?(result)

      UIBackgroundFetchResultNoData
    end

  end
end
