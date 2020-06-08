LATEST_RELEASE := $(shell curl -s http://chromedriver.storage.googleapis.com/LATEST_RELEASE)
MAC64_FILE = "chromedriver_mac64.zip"
MAC64_URL := "http://chromedriver.storage.googleapis.com/$(LATEST_RELEASE)/$(MAC64_FILE)"
LINUX64_FILE = "chromedriver_linux64.zip"
LINUX64_URL := "http://chromedriver.storage.googleapis.com/$(LATEST_RELEASE)/$(LINUX64_FILE)"
DRIVER_BIN_FILE = "./chromedriver"

clean:
	rm $(DRIVER_BIN_FILE)

bundle_install:
	bundle install --path=vendor/bundle

driver_download_mac:
	curl -O -L $(MAC64_URL)
	unzip $(MAC64_FILE)
	chmod u+x $(DRIVER_BIN_FILE)
	rm $(MAC64_FILE)

driver_download_linux:
	bundle install --path=vendor/bundle
	curl -O -L $(LINUX64_URL)
	unzip $(LINUX64_FILE)
	chmod u+x $(DRIVER_BIN_FILE)
	rm $(LINUX64_FILE)

headless_chrome_install_centos:
	sudo cp google-chrome.repo /etc/yum.repos.d/
	sudo yum install -y google-chrome

test_command:
	bundle exec ruby message_parse_test.rb --driver_path $(DRIVER_BIN_FILE)

test_command_headless:
	bundle exec ruby message_parse_test.rb --driver_path $(DRIVER_BIN_FILE) --headless
