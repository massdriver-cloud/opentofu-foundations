package lib
import (
	"net/http"
	"encoding/json"
	"io/ioutil"
	"fmt"
	"log"
)

// API Docs can be found at
// https://fiscaldata.treasury.gov/api-documentation/

const baseUrl = "https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v1/accounting/od/rates_of_exchange" 

type Record struct {
	Currency string `json:"country_currency_desc"`
	ExchangeRate string `json:"exchange_rate"`
	CreatedAt string `json:"record_date"`
}

type Metadata struct {
	Count int `json:"count"`
	Labels map[string]string `json:"labels"`
	DataTypes map[string]string `json:"dataTypes"`
	DataFormats map[string]string `json:"dataFormats"`
	TotalCount int `json:"total-count"`
	Links map[string]string `json:"links"`
}

type Response struct {
	Data []Record `json:"data"`
	Metadata Metadata `json:"meta"`
}

type RequestOptions struct {
	Currencies string `tf:"currencies"`
}

func ExchangeRate(options RequestOptions) Record {
	var response Response
	queryParams := fmt.Sprintf("fields=country_currency_desc,exchange_rate,record_date&filter=country_currency_desc:in:(%s),record_date:gte:2020-01-01&sort=-record_date&page[size]=1", options.Currencies)
	requestUrl := fmt.Sprintf("%s?%s", baseUrl, queryParams)
	resp, err := http.Get(requestUrl)

	if err != nil {
		log.Fatal(err)
	}

	body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		log.Fatal(err)
	}

	err = json.Unmarshal(body, &response)
	
	if err != nil {
		log.Fatal(err)
	}

	return response.Data[0]
}
