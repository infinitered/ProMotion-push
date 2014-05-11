class OtherDelegate; end
class TestDelegate < OtherDelegate
  include ProMotion::DelegateModule

  def on_load(app, options)
  end
end
