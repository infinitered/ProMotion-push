# ProMotion-push

ProMotion-push is push notification support, extracted from the
popular RubyMotion gem [ProMotion](https://github.com/clearsightstudio/ProMotion) and is maintained by [Infinite Red](http://infinite.red), a web and mobile development company based in Portland, OR and San Francisco, CA.

## Installation

```ruby
gem 'ProMotion-push'
```

## Usage

### AppDelegate

Include PM::DelegateNotifications to add a few methods to PM::Delegate.

```ruby
# app/app_delegate.rb
class AppDelegate < PM::Delegate
  include PM::DelegateNotifications

  def on_load(app, options)
    register_for_push_notifications :badge, :sound, :alert, :newsstand
    PM.logger.info registered_push_notifications
    # ...
  end

  def on_unload
    unregister_for_push_notifications
  end

  def on_push_registration(token, error)
    PM.logger.info token.description
  end

  def on_push_notification(notification, launched)
    PM.logger.info notification.to_json
  end
end
```

#### register_for_push_notifications(*types)

Method you can call to register your app for push notifications. You'll also want to implement
`on_push_notification` and `on_push_registration`.

```ruby
def on_load(app, options)
    register_for_push_notifications :badge, :sound, :alert, :newsstand # or :all
    # ...
end
```

#### unregister_for_push_notifications

Unregisters from all push notifications.

```ruby
def logging_out
  unregister_for_push_notifications
end
```

**NOTE:** From a screen you'll have to reference the app_delegate:

```ruby
def log_out
  app_delegate.unregister_for_push_notifications
end
```

#### on_push_registration(token, error)

Method that is called after you attempt to register for notifications. Either `token` or `error`
will be provided.

```ruby
def on_push_registration(token, error)
  if token
    # Push token to your server
  else
    # Display the error
  end
end
```

#### on_push_notification(notification, launched)

Method called when the app is launched via a notification or a notification is received
in-app. `notification` is a
[PM::PushNotification](https://github.com/clearsightstudio/ProMotion/wiki/API-Reference:-ProMotion::PushNotification)
object which is a thin wrapper around the notification hash provided by iOS. `launched`
is a boolean letting you know whether the notification initiated your app's launch (true) or
if your app was already running (false).

```ruby
def on_push_notification(notification, launched)
  notification.to_json  # => '{"aps":{"alert":"My test notification","badge":3,"sound":"default"}, "custom": "Jamon Holmgren"}'
  notification.alert    # => "My test notification"
  notification.badge    # => 3
  notification.sound    # => "default"
  notification.custom   # => "Jamon Holmgren"
end
```

ProMotion-push automatically adds support for handling push notifications while your app is in the background. If your push notification payload includes `content-available: 1` then you may have an opportunity to pre-fetch data. The return value of the `on_push_notification` method should be a `UIBackgroundFetchResult` that best matches your result. The default is `UIBackgroundFetchResultNoData`, so you don't need to return anything if you did not fetch any data. For example:

```ruby
# Payload:
# {
#   "aps": {
#     "content-available": 1,
#     "alert": "My test notification",
#     "badge": 3,
#     "sound": "default"
#   },
#   "type": "new_messages"
# }

def on_push_notification(notification, launched)
  if notification.type == "new_messages"
    MessagesScreen.load_data
    UIBackgroundFetchResultNewData
  end
end
```

#### registered_push_notifications

Returns the currently registered notifications as an array of symbols.

```ruby
def some_method
  registered_push_notifications # => [ :badge, :sound, :alert, :newsstand ]
end
```


### ProMotion::PushNotification

You receive this object in your AppDelegate's `on_push_notification` method.

```ruby
def on_push_notification(notification, launched)
  notification.to_json  # => '{"aps":{"alert":"My test notification","badge":3,"sound":"default"}, "custom": "Jamon Holmgren"}'
  notification.alert    # => "My test notification"
  notification.badge    # => 3
  notification.sound    # => "default"
  notification.custom   # => "Jamon Holmgren"
end
```

The best way to test push notifications is on a device, but it's often useful to test
them in the simulator. We provide a way to do that from the REPL or in code.

```ruby
# In REPL
PM::PushNotification.simulate(alert: "My test", badge: 4, sound: "default", custom: "custom", launched: true)
```
```ruby
def on_push_notification(notification, launched)
  notification.aps # => { alert: "My test", badge: sound: "default"}
  notification.alert # => "My test"
  notification.custom # => 'custom'
end
```

#### alert

Returns the alert string for the push notification object.

```ruby
notification.alert    # => "My test notification"
```

#### badge

Returns the badge number for the push notification object, if it exists.

```ruby
notification.badge    # => 3
```

#### sound

Returns a string representing the sound for the push notification object, if it exists.

```ruby
notification.sound    # => "sound"
```

#### to_json

Returns a json string representation of the push notification object.

```ruby
notification.to_json  # => '{"aps":{"alert":"My test notification","sound":"default"},"custom":"something custom"}'
```

#### (custom methods)

A `method_missing` implementation will respond to all methods that are keys in the notification hash. It
will raise a NoMethodError if there isn't a corresponding key.

```ruby
# Given: '{"aps":{"alert":"My test notification","sound":"default"}, "my_custom_key": "My custom data"}'
notification.my_custom_key # => "My custom data"
notification.no_key_here # => NoMethodError
```

#### notification

Returns the raw notification object provided by iOS.

```ruby
notification.notification # => Hash
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Make some specs pass
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
