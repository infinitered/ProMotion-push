describe "push notifications" do
  before { @subject = AppDelegate.new }

  it "should handle push notifications" do
    @subject.mock!(:on_push_notification) do |notification, was_launched|
      notification.should.be.kind_of(ProMotion::PushNotification)
      notification.alert.should == "Eating Bacon"
      notification.badge.should == 42
      notification.sound.should == "jamon"
      @subject.aps_notification.should == notification
    end

    launch_options = { UIApplicationLaunchOptionsRemoteNotificationKey => ProMotion::PushNotification.fake_notification(alert: "Eating Bacon", badge: 42, sound: "jamon").notification }
    @subject.application(UIApplication.sharedApplication, willFinishLaunchingWithOptions: nil)
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions:launch_options )
  end

  it "should return false for was_launched if the app is currently active on screen" do
    @subject.mock!(:on_push_notification) do |notification, was_launched|
      was_launched.should.be.false
    end

    fake_app = Struct.new(:applicationState).new(UIApplicationStateActive)
    remote_notification = PM::PushNotification.fake_notification.notification
    @subject.application(fake_app, didReceiveRemoteNotification: remote_notification)
  end

  it "should return true for was_launched if app was launched from background" do
    @subject.mock!(:on_push_notification) do |notification, was_launched|
      was_launched.should.be.true
    end

    fake_app = Struct.new(:applicationState).new(UIApplicationStateBackground)
    remote_notification = PM::PushNotification.fake_notification.notification
    @subject.application(fake_app, didReceiveRemoteNotification: remote_notification)
  end

  it "should return true for was_launched if the app wasn't running" do
    @subject.mock!(:on_push_notification) do |notification, was_launched|
      was_launched.should.be.true
    end

    launch_options = { UIApplicationLaunchOptionsRemoteNotificationKey => PM::PushNotification.fake_notification.notification }
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions:launch_options )
  end

  describe "on a version lower than iOS 8" do
    before do
      @app = IOS7Application.new
      UIApplication.stub!(:sharedApplication, return: @app)
    end

    it "should allow registration for push notifications on < iOS 8" do
      @subject.register_for_push_notifications(:badge)
      @app.types.should.equal(UIRemoteNotificationTypeBadge)
    end

    it "should return nil for :register_push_notification_category" do
      @subject.register_push_notification_category("category", [], {}).should.be.nil
    end

    it "should return the registered push notification types as an array" do
      @subject.registered_push_notifications.should == []
      bits = 0
      types = []
      {
        badge:      UIRemoteNotificationTypeBadge,
        sound:      UIRemoteNotificationTypeSound,
        alert:      UIRemoteNotificationTypeAlert,
        newsstand:  UIRemoteNotificationTypeNewsstandContentAvailability }.each do |symbol, bit|
          @app.stub!(:enabledRemoteNotificationTypes, return: bit)
          @subject.registered_push_notifications.should == [symbol]

          bits |= bit
          types << symbol
          @app.stub!(:enabledRemoteNotificationTypes, return: bits)
          @subject.registered_push_notifications.should == types
        end
    end
  end

  describe "on iOS 8 +" do
    before do
      @app = IOS8Application.new
      UIApplication.stub!(:sharedApplication, return: @app)
    end

    it "should allow registration of push notifications on iOS 8+" do
      @subject.register_for_push_notifications(:badge)

      @app.registered_for_notifications.should.be.true
      @app.settings.types.should.equal(UIRemoteNotificationTypeBadge)
      @app.settings.categories.count.should.equal(0)
    end

    it "should work properly when using register_push_notification_category" do
      @method_call = @subject.register_push_notification_category("my category", [], {})
      @method_call.class.should.equal(UIMutableUserNotificationCategory)
      @method_call.identifier.should.equal("my category")
    end

    it "should take into consideration the categories used with register_push_notification_category" do
      @subject.register_push_notification_category("my category", [], {})
      @subject.register_for_push_notifications(:badge)
      @app.settings.categories.count.should.equal(1)
      @app.settings.categories.allObjects[0].identifier.should.equal("my category")
    end

    it "should call on_push_notification_action if its implemented" do

      @subject.mock!(:on_push_notification_action) do |action, notification|
        notification.should.be.kind_of(ProMotion::PushNotification)
        notification.alert.should == "Eating Bacon"
        notification.badge.should == 42
        notification.sound.should == "jamon"
        @subject.aps_notification.should == notification
      end

      notification = ProMotion::PushNotification.fake_notification(alert: "Eating Bacon", badge: 42, sound: "jamon").notification
      @subject.application(UIApplication.sharedApplication, handleActionWithIdentifier: "my category", forRemoteNotification: notification, completionHandler: -> {})
    end

    it "should return the registered push notification types as an array" do
      @subject.registered_push_notifications.should == []
      bits = 0
      types = []
      {
        badge:      UIRemoteNotificationTypeBadge,
        sound:      UIRemoteNotificationTypeSound,
        alert:      UIRemoteNotificationTypeAlert,
        newsstand:  UIRemoteNotificationTypeNewsstandContentAvailability }.each do |symbol, bit|
          @app.stub!(:currentUserNotificationSettings, return: stub(:types, return: bit))
          @subject.registered_push_notifications.should == [symbol]

          bits |= bit
          types << symbol
          @app.stub!(:currentUserNotificationSettings, return: stub(:types, return: bits))
          @subject.registered_push_notifications.should == types
        end
    end
  end

  class IOS7Application
    attr_accessor :types
    def registerForRemoteNotificationTypes(types)
      self.types = types
    end
    def enabledRemoteNotificationTypes
      0
    end
  end
  class IOS8Application
    attr_accessor :settings
    attr_accessor :registered_for_notifications

    def registerUserNotificationSettings(value)
      self.settings = value
    end

    def registerForRemoteNotifications
      self.registered_for_notifications = true
    end
    def currentUserNotificationSettings
      mock(:types, return: 0)
    end
  end
end
