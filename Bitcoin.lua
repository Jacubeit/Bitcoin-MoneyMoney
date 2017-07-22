-- Inofficial Bitcoin Extension for MoneyMoney
-- Fetches Bitcoin quantity for addresses via blockexplorer API
-- Fetches Bitcoin price in EUR via coinmarketcap API
-- Returns cryptoassets as securities
--
-- Username: Bitcoin Adresses comma seperated
-- Password: [Whatever]

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
  version = 0.1,
  description = "Include your Bitcoins as cryptoportfolio in MoneyMoney by providing Bitcoin addresses as usernme (comma seperated) and a random Password",
  services= { "Bitcoin" }
}

local bitcoinAddress
local connection = Connection()
local currency = "EUR" -- fixme: make dynamik if MM enables input field

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
  prices = requestBitcoinPrice()

  for address in string.gmatch(bitcoinAddress, '([^,]+)') do
    bitcoinQuantity = requestBitcoinQuantityForBitcoinAddress(address)

    s[#s+1] = {
      name = address,
      currency = nil,
      market = "cryptocompare",
      quantity = bitcoinQuantity,
      price = prices["price_eur"],
    }
  end

  return {securities = s}
end

function EndSession ()
end


-- Querry Functions
function requestBitcoinPrice()
  response = connection:request("GET", cryptocompareRequestUrl(), {})
  json = JSON(response)

  return json:dictionary()[1]
end

function requestBitcoinQuantityForBitcoinAddress(bitcoinAddress)
  response = connection:request("GET", bitcoinRequestUrl(bitcoinAddress), {})
  json = JSON(response)
  
  return convertSatoshiToBitcoin(response)
end


-- Helper Functions
function convertSatoshiToBitcoin(satoshi)
  return satoshi / 100000000  
end

function cryptocompareRequestUrl()
  return "https://api.coinmarketcap.com/v1/ticker/bitcoin/?convert=EUR"
end 

function bitcoinRequestUrl(bitcoinAddress)
  return "https://blockexplorer.com/api/addr/" .. bitcoinAddress .. "/balance"
end

