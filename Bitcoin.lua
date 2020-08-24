-- Inofficial Bitcoin Extension for MoneyMoney
-- Fetches Bitcoin quantity for addresses via api.blockcypher.com API
-- Fetches Bitcoin price in EUR via blockchain.info API
-- Returns cryptoassets as securities
--
-- Username: Bitcoin Adresses comma separated

-- MIT License

-- Copyright (c) 2017 Jacubeit

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


WebBanking{
  version = 0.3,
  description = "Include your Bitcoins as cryptoportfolio in MoneyMoney by providing Bitcoin addresses as username (comma separated).",
  services= { "Bitcoin" }
}

local bitcoinAddress
local connection = Connection()
local currency = "EUR" -- fixme: make dynamic if MM enables input field

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Bitcoin"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  bitcoinAddress = username:gsub("%s+", "")
end

function ListAccounts (knownAccounts)
  local account = {
    name = "Bitcoin",
    accountNumber = "Bitcoin",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  local s = {}
  BTCinEURprice = requestBitcoinPrice()

  for address in string.gmatch(bitcoinAddress, '([^,]+)') do
    bitcoinQuantity = requestBitcoinQuantityForBitcoinAddress(address)

    s[#s+1] = {
      name = address,
      currency = nil,
      market = "blockchain.info",
      quantity = bitcoinQuantity,
      price = BTCinEURprice,
    }
  end

  return {securities = s}
end

function EndSession ()
end


-- Query Functions
function requestBitcoinPrice()
  response = connection:request("GET", priceRequestUrl(), {})
  json = JSON(response)
  return json:dictionary()["EUR"]["last"]
end

function requestBitcoinQuantityForBitcoinAddress(bitcoinAddress)
  response = connection:request("GET", bitcoinRequestUrl(bitcoinAddress), {})

  json = JSON(response)
  satoshi = json:dictionary()["balance"]

  return convertSatoshiToBitcoin(satoshi)
end


-- Helper Functions
function convertSatoshiToBitcoin(satoshi)
  return satoshi / 100000000
end

function priceRequestUrl()
  return "https://blockchain.info/ticker"
end

function bitcoinRequestUrl(bitcoinAddress)
  return "https://api.blockcypher.com/v1/btc/main/addrs/" .. bitcoinAddress
end
