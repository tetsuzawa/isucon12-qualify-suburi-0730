isuports: test go.mod go.sum *.go cmd/isuports/*
	go build -o isuports ./cmd/isuports

test:
	go test -v ./...

install-fgprof:
	go get github.com/felixge/fgprof

install-newrelic:
	go get github.com/newrelic/go-agent/v3/newrelic
	go get github.com/labstack/echo/v4/middleware
	go get github.com/newrelic/go-agent/v3/integrations/nrecho-v4
	go get github.com/newrelic/go-agent/v3/integrations/nrmysql

install-go-json:
	go get github.com/goccy/go-json
