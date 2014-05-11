# Re-open ProMotion's DelegateModule and Delegate to include our module
module ProMotion
  module DelegateModule
    include ProMotion::DelegateNotifications
  end

  class Delegate
    include ProMotion::DelegateNotifications
  end
end
