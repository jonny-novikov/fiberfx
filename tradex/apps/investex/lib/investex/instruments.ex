defmodule Investex.Instruments do
  @moduledoc """
  InstrumentsService — the 27 instrument-reference read RPCs (rung TRD.9.2,
  `docs/exchange/trd.9.2.specs.md` §"The 41-function surface";
  instruments.pb.ex:1870-1984).

  Each function is a **1:1 pass-through** mirroring `Investex.Users` (RQ-1/D-1):
  it takes a pre-built typed `%Proto.<Request>{}` as its single argument (after
  the client) and forwards it to `Investex.Caller.unary(client,
  &InstrumentsService.Stub.<fun>/3, request)`, returning `{:ok,
  %Proto.<Response>{}} | {:error, Investex.Error.t()}`. The function is
  **stateless given a client handle** (INV-5): the channel and the per-RPC
  metadata are read from the supervised `Investex.Client` inside the shared
  `Caller` seam; no exception escapes (channel-level and gRPC-status failures
  fold into the typed `Investex.Error`).

  The function name is `snake(RPC)` — the name `use GRPC.Stub` generates on the
  `Stub` (stub.ex:69) — and the arity is uniform `/2` (client + typed request,
  RQ-1). This symmetry (`snake(RPC) == fun name == Stub fun name`) is what the
  pass-through-fidelity check (G-FID) asserts across all 41 read functions. The
  caller pre-builds the typed `%Proto.<Request>{}`; this layer adds no
  request-builder (the proto struct IS the typed request, D-1).
  """

  alias Investex.Caller
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
  alias Tinkoff.Public.Invest.Api.Contract.V1.InstrumentsService.Stub

  @doc "TradingSchedules — trading schedules for exchanges/instruments (instruments.pb.ex:1877)."
  @spec trading_schedules(Investex.Client.t(), Proto.TradingSchedulesRequest.t()) ::
          {:ok, Proto.TradingSchedulesResponse.t()} | {:error, Investex.Error.t()}
  def trading_schedules(client, %Proto.TradingSchedulesRequest{} = request) do
    Caller.unary(client, &Stub.trading_schedules/3, request)
  end

  @doc "BondBy — a single bond by identifier (instruments.pb.ex:1881)."
  @spec bond_by(Investex.Client.t(), Proto.InstrumentRequest.t()) ::
          {:ok, Proto.BondResponse.t()} | {:error, Investex.Error.t()}
  def bond_by(client, %Proto.InstrumentRequest{} = request) do
    Caller.unary(client, &Stub.bond_by/3, request)
  end

  @doc "Bonds — the list of bonds (instruments.pb.ex:1885)."
  @spec bonds(Investex.Client.t(), Proto.InstrumentsRequest.t()) ::
          {:ok, Proto.BondsResponse.t()} | {:error, Investex.Error.t()}
  def bonds(client, %Proto.InstrumentsRequest{} = request) do
    Caller.unary(client, &Stub.bonds/3, request)
  end

  @doc "GetBondCoupons — the coupon schedule for a bond (instruments.pb.ex:1889)."
  @spec get_bond_coupons(Investex.Client.t(), Proto.GetBondCouponsRequest.t()) ::
          {:ok, Proto.GetBondCouponsResponse.t()} | {:error, Investex.Error.t()}
  def get_bond_coupons(client, %Proto.GetBondCouponsRequest{} = request) do
    Caller.unary(client, &Stub.get_bond_coupons/3, request)
  end

  @doc "CurrencyBy — a single currency by identifier (instruments.pb.ex:1893)."
  @spec currency_by(Investex.Client.t(), Proto.InstrumentRequest.t()) ::
          {:ok, Proto.CurrencyResponse.t()} | {:error, Investex.Error.t()}
  def currency_by(client, %Proto.InstrumentRequest{} = request) do
    Caller.unary(client, &Stub.currency_by/3, request)
  end

  @doc "Currencies — the list of currencies (instruments.pb.ex:1897)."
  @spec currencies(Investex.Client.t(), Proto.InstrumentsRequest.t()) ::
          {:ok, Proto.CurrenciesResponse.t()} | {:error, Investex.Error.t()}
  def currencies(client, %Proto.InstrumentsRequest{} = request) do
    Caller.unary(client, &Stub.currencies/3, request)
  end

  @doc "EtfBy — a single ETF by identifier (instruments.pb.ex:1901)."
  @spec etf_by(Investex.Client.t(), Proto.InstrumentRequest.t()) ::
          {:ok, Proto.EtfResponse.t()} | {:error, Investex.Error.t()}
  def etf_by(client, %Proto.InstrumentRequest{} = request) do
    Caller.unary(client, &Stub.etf_by/3, request)
  end

  @doc "Etfs — the list of ETFs (instruments.pb.ex:1905)."
  @spec etfs(Investex.Client.t(), Proto.InstrumentsRequest.t()) ::
          {:ok, Proto.EtfsResponse.t()} | {:error, Investex.Error.t()}
  def etfs(client, %Proto.InstrumentsRequest{} = request) do
    Caller.unary(client, &Stub.etfs/3, request)
  end

  @doc "FutureBy — a single future by identifier (instruments.pb.ex:1909)."
  @spec future_by(Investex.Client.t(), Proto.InstrumentRequest.t()) ::
          {:ok, Proto.FutureResponse.t()} | {:error, Investex.Error.t()}
  def future_by(client, %Proto.InstrumentRequest{} = request) do
    Caller.unary(client, &Stub.future_by/3, request)
  end

  @doc "Futures — the list of futures (instruments.pb.ex:1913)."
  @spec futures(Investex.Client.t(), Proto.InstrumentsRequest.t()) ::
          {:ok, Proto.FuturesResponse.t()} | {:error, Investex.Error.t()}
  def futures(client, %Proto.InstrumentsRequest{} = request) do
    Caller.unary(client, &Stub.futures/3, request)
  end

  @doc "OptionBy — a single option by identifier (instruments.pb.ex:1917)."
  @spec option_by(Investex.Client.t(), Proto.InstrumentRequest.t()) ::
          {:ok, Proto.OptionResponse.t()} | {:error, Investex.Error.t()}
  def option_by(client, %Proto.InstrumentRequest{} = request) do
    Caller.unary(client, &Stub.option_by/3, request)
  end

  @doc "Options — the list of options (instruments.pb.ex:1921)."
  @spec options(Investex.Client.t(), Proto.InstrumentsRequest.t()) ::
          {:ok, Proto.OptionsResponse.t()} | {:error, Investex.Error.t()}
  def options(client, %Proto.InstrumentsRequest{} = request) do
    Caller.unary(client, &Stub.options/3, request)
  end

  @doc "OptionsBy — options filtered by underlying (instruments.pb.ex:1925; FilterOptionsRequest)."
  @spec options_by(Investex.Client.t(), Proto.FilterOptionsRequest.t()) ::
          {:ok, Proto.OptionsResponse.t()} | {:error, Investex.Error.t()}
  def options_by(client, %Proto.FilterOptionsRequest{} = request) do
    Caller.unary(client, &Stub.options_by/3, request)
  end

  @doc "ShareBy — a single share by identifier (instruments.pb.ex:1929)."
  @spec share_by(Investex.Client.t(), Proto.InstrumentRequest.t()) ::
          {:ok, Proto.ShareResponse.t()} | {:error, Investex.Error.t()}
  def share_by(client, %Proto.InstrumentRequest{} = request) do
    Caller.unary(client, &Stub.share_by/3, request)
  end

  @doc "Shares — the list of shares (instruments.pb.ex:1933)."
  @spec shares(Investex.Client.t(), Proto.InstrumentsRequest.t()) ::
          {:ok, Proto.SharesResponse.t()} | {:error, Investex.Error.t()}
  def shares(client, %Proto.InstrumentsRequest{} = request) do
    Caller.unary(client, &Stub.shares/3, request)
  end

  @doc "GetAccruedInterests — accrued interest for a bond over a range (instruments.pb.ex:1937)."
  @spec get_accrued_interests(Investex.Client.t(), Proto.GetAccruedInterestsRequest.t()) ::
          {:ok, Proto.GetAccruedInterestsResponse.t()} | {:error, Investex.Error.t()}
  def get_accrued_interests(client, %Proto.GetAccruedInterestsRequest{} = request) do
    Caller.unary(client, &Stub.get_accrued_interests/3, request)
  end

  @doc "GetFuturesMargin — margin parameters for a future (instruments.pb.ex:1941)."
  @spec get_futures_margin(Investex.Client.t(), Proto.GetFuturesMarginRequest.t()) ::
          {:ok, Proto.GetFuturesMarginResponse.t()} | {:error, Investex.Error.t()}
  def get_futures_margin(client, %Proto.GetFuturesMarginRequest{} = request) do
    Caller.unary(client, &Stub.get_futures_margin/3, request)
  end

  @doc "GetInstrumentBy — a single instrument of any kind by identifier (instruments.pb.ex:1945)."
  @spec get_instrument_by(Investex.Client.t(), Proto.InstrumentRequest.t()) ::
          {:ok, Proto.InstrumentResponse.t()} | {:error, Investex.Error.t()}
  def get_instrument_by(client, %Proto.InstrumentRequest{} = request) do
    Caller.unary(client, &Stub.get_instrument_by/3, request)
  end

  @doc "GetDividends — the dividend schedule for a share (instruments.pb.ex:1949)."
  @spec get_dividends(Investex.Client.t(), Proto.GetDividendsRequest.t()) ::
          {:ok, Proto.GetDividendsResponse.t()} | {:error, Investex.Error.t()}
  def get_dividends(client, %Proto.GetDividendsRequest{} = request) do
    Caller.unary(client, &Stub.get_dividends/3, request)
  end

  @doc "GetAssetBy — a single asset by identifier (instruments.pb.ex:1953)."
  @spec get_asset_by(Investex.Client.t(), Proto.AssetRequest.t()) ::
          {:ok, Proto.AssetResponse.t()} | {:error, Investex.Error.t()}
  def get_asset_by(client, %Proto.AssetRequest{} = request) do
    Caller.unary(client, &Stub.get_asset_by/3, request)
  end

  @doc "GetAssets — the list of assets (instruments.pb.ex:1957)."
  @spec get_assets(Investex.Client.t(), Proto.AssetsRequest.t()) ::
          {:ok, Proto.AssetsResponse.t()} | {:error, Investex.Error.t()}
  def get_assets(client, %Proto.AssetsRequest{} = request) do
    Caller.unary(client, &Stub.get_assets/3, request)
  end

  @doc "GetFavorites — the caller's favorite instruments (instruments.pb.ex:1961)."
  @spec get_favorites(Investex.Client.t(), Proto.GetFavoritesRequest.t()) ::
          {:ok, Proto.GetFavoritesResponse.t()} | {:error, Investex.Error.t()}
  def get_favorites(client, %Proto.GetFavoritesRequest{} = request) do
    Caller.unary(client, &Stub.get_favorites/3, request)
  end

  @doc "EditFavorites — add/remove favorite instruments (instruments.pb.ex:1965)."
  @spec edit_favorites(Investex.Client.t(), Proto.EditFavoritesRequest.t()) ::
          {:ok, Proto.EditFavoritesResponse.t()} | {:error, Investex.Error.t()}
  def edit_favorites(client, %Proto.EditFavoritesRequest{} = request) do
    Caller.unary(client, &Stub.edit_favorites/3, request)
  end

  @doc "GetCountries — the list of countries (instruments.pb.ex:1969)."
  @spec get_countries(Investex.Client.t(), Proto.GetCountriesRequest.t()) ::
          {:ok, Proto.GetCountriesResponse.t()} | {:error, Investex.Error.t()}
  def get_countries(client, %Proto.GetCountriesRequest{} = request) do
    Caller.unary(client, &Stub.get_countries/3, request)
  end

  @doc "FindInstrument — search instruments by query string (instruments.pb.ex:1973)."
  @spec find_instrument(Investex.Client.t(), Proto.FindInstrumentRequest.t()) ::
          {:ok, Proto.FindInstrumentResponse.t()} | {:error, Investex.Error.t()}
  def find_instrument(client, %Proto.FindInstrumentRequest{} = request) do
    Caller.unary(client, &Stub.find_instrument/3, request)
  end

  @doc "GetBrands — the list of instrument brands (instruments.pb.ex:1977)."
  @spec get_brands(Investex.Client.t(), Proto.GetBrandsRequest.t()) ::
          {:ok, Proto.GetBrandsResponse.t()} | {:error, Investex.Error.t()}
  def get_brands(client, %Proto.GetBrandsRequest{} = request) do
    Caller.unary(client, &Stub.get_brands/3, request)
  end

  @doc """
  GetBrandBy — a single brand by identifier (instruments.pb.ex:1981).

  NOTE the asymmetry the spec pins: the response is the **bare** `Proto.Brand`
  message, NOT `BrandResponse` (instruments.pb.ex:1983 — every other RPC in this
  service returns a `…Response`). Cited from the generated `Service` declaration,
  never inferred from the name.
  """
  @spec get_brand_by(Investex.Client.t(), Proto.GetBrandRequest.t()) ::
          {:ok, Proto.Brand.t()} | {:error, Investex.Error.t()}
  def get_brand_by(client, %Proto.GetBrandRequest{} = request) do
    Caller.unary(client, &Stub.get_brand_by/3, request)
  end
end
