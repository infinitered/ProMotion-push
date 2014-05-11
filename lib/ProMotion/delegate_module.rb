# Re-open ProMotion's DelegateModule and Delegate to include our module
module ProMotion
  module DelegateModule
    include ProMotion::DelegateNotifications
  end

  class Delegate < ProMotion::DelegateParent
    include ProMotion::DelegateNotifications
  end
end
