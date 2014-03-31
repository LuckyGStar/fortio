module WrappedButton
  def wrapped_button(*args, &block)
    template.content_tag :div, :class => "form-group" do
      template.content_tag :div, :class => "form-submit col-sm-11" do

        options = args.extract_options!
        loading = self.object.new_record? ? I18n.t('simple_form.creating') : I18n.t('simple_form.updating')
        options[:"data-loading-text"] = [loading, options[:"data-loading-text"]].compact
        options[:class] = ['btn btn-default btn-lg pull-right', options[:class]].compact

        args << options

        if cancel = options.delete(:cancel)
          class_text = 'btn btn-info btn-lg pull-right'
          cancel_text = options.delete(:cancel_text) || I18n.t('simple_form.buttons.cancel')

          if no_submit = options.delete(:no_submit)
            template.link_to(cancel_text, cancel, class: class_text)
          else
            submit(*args) + template.link_to(cancel_text, cancel, class: class_text)
          end
        else
          block_view = block ? template.capture(&block) : ""
          submit_view = options.delete(:no_submit) ? "" : submit(*args)
          block_view + submit_view
        end
      end
    end
  end
end
SimpleForm::FormBuilder.send :include, WrappedButton
