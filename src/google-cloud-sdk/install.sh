#!/bin/bash
set -e

echo "Activating feature 'google-cloud-sdk'"

VERSION=${VERSION:-latest}
COMPONENTS=${COMPONENTS:-none}

if [ $(uname -m) = 'x86_64' ]; then echo -n "x86_64" >/tmp/arch; else echo -n "arm" >/tmp/arch; fi
ARCH=$(cat /tmp/arch)

# If VERSION is latest then get the latest version from dl page
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ] || [ -n "$VERSION" ]; then
	# Define the URL of the Google Cloud SDK download page.
	DOWNLOAD_PAGE_URL="https://cloud.google.com/sdk/docs/install"

	# Use curl to download the page content and extract the version number using grep.
	LATEST_VERSION=$(curl -s "$DOWNLOAD_PAGE_URL" | grep -o "google-cloud-cli-[0-9.]*" | head -n 1 | sed 's/google-cloud-cli-//')

	# If LATEST_VERSION is empty then exit with error.
	if [ -z "$LATEST_VERSION" ]; then
		echo "Unable to determine latest version from download page: $DOWNLOAD_PAGE_URL"
		exit 1
	fi

	VERSION=$LATEST_VERSION
	echo "Latest version of Google Cloud SDK is $LATEST_VERSION"
fi

# Download and extract the Google Cloud SDK archive.
DOWNLOAD_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-$VERSION-linux-$ARCH.tar.gz
TAR_FILE=google-cloud-cli.tar.gz
curl -o $TAR_FILE "$DOWNLOAD_URL"
echo "Finished downloading Google Cloud SDK $VERSION"

echo "Extracting Google Cloud SDK $VERSION, This may take a few minutes"
tar -xf $TAR_FILE
rm $TAR_FILE
echo "Finished extracting Google Cloud SDK $VERSION"

echo "Moving Google Cloud SDK $VERSION to /usr/share/google-cloud-sdk"
mkdir -p /usr/share
sudo mv ./google-cloud-sdk /usr/share/google-cloud-sdk
echo "Finished moving Google Cloud SDK $VERSION to /usr/share/google-cloud-sdk"

# ## If COMPONENTS is set and not none and not empty
if [ "$COMPONENTS" != "none" ] && [ "$COMPONENTS" != "" ] && [ -n "$COMPONENTS" ]; then
	## for each component in COMPONENTS
	for component in $(echo $COMPONENTS | tr "," "\n"); do
		## install component
		sudo /usr/share/google-cloud-sdk/bin/gcloud components install $component
		echo "Finished installing component $component"
	done
fi

echo "Finished installing all components"

# Setup execution commands
for file in /usr/share/google-cloud-sdk/bin/*; do
	sudo ln -f -n -s $file /usr/local/bin/$(basename $file)
done

echo "Finished installing Google Cloud SDK $VERSION"
