namespace :deploy do
  desc 'touching client side i8n files'
  task touch_client_i18n_files: :environment do
    Dir[Rails.root.join('app', 'assets', 'javascripts','locales', '*.js.erb')].each do |path|
      File.open(path, 'a') do |f|
        f << "\n//#{Time.now.to_s}"
      end
    end
  end
end
