---

name: java-coding-standards
description: "適用於 Spring Boot 與 Quarkus 服務的 Java 編碼標準：命名、不可變性、Optional 使用方式、Streams、例外處理、泛型、CDI、Reactive 模式與專案結構。會依框架自動套用對應慣例。"
-----------

# Java 編碼標準

適用於 Spring Boot 與 Quarkus 服務中可讀、可維護的 Java 17+ 程式碼標準。

## 使用時機

* 撰寫或審查 Spring Boot、Quarkus 專案中的 Java 程式碼
* 強制執行命名、不可變性、例外處理慣例
* 使用 records、sealed classes、pattern matching 等 Java 17+ 功能
* 審查 Optional、Streams、泛型的使用方式
* 規劃 package 與專案結構
* **[QUARKUS]**：使用 CDI scopes、Panache entities、Reactive pipelines

## 運作方式

### 框架偵測

套用標準前，先從 build file 判斷使用的框架：

* Build file 包含 `quarkus` → 套用 **[QUARKUS]** 慣例
* Build file 包含 `spring-boot` → 套用 **[SPRING]** 慣例
* 兩者皆未偵測到 → 僅套用共用慣例

## 核心原則

* 清楚優先於炫技
* 預設不可變；降低共享可變狀態
* 快速失敗，並提供有意義的例外訊息
* 維持一致的命名與 package 結構
* **[QUARKUS]**：優先使用 build-time 處理，盡量避免 runtime reflection

## 範例

以下章節提供 Spring Boot、Quarkus 與共用 Java 範例，涵蓋命名、不可變性、依賴注入、Reactive 程式碼、例外處理、專案結構、日誌、設定與測試。

## 命名

```java
// PASS: Class / Record 使用 PascalCase
public class MarketService {}
public record Money(BigDecimal amount, Currency currency) {}

// PASS: Method / Field 使用 camelCase
private final MarketRepository marketRepository;
public Market findBySlug(String slug) {}

// PASS: 常數使用 UPPER_SNAKE_CASE
private static final int MAX_PAGE_SIZE = 100;

// PASS: [QUARKUS] JAX-RS resource 命名為 *Resource，不使用 *Controller
public class MarketResource {}

// PASS: [SPRING] REST controller 命名為 *Controller
public class MarketController {}
```

## 不可變性

```java
// PASS: 優先使用 record 與 final field
public record MarketDto(Long id, String name, MarketStatus status) {}

public class Market {
  private final Long id;
  private final String name;
  // 僅提供 getter，不提供 setter
}

// PASS: [QUARKUS] Panache active-record entity 使用 public field，這是 Quarkus 慣例
@Entity
public class Market extends PanacheEntity {
  public String name;
  public MarketStatus status;
  // Panache 會在 build time 產生 accessor；public field 是慣用寫法
}

// PASS: [QUARKUS] Panache MongoDB entity
@MongoEntity(collection = "markets")
public class Market extends PanacheMongoEntity {
  public String name;
  public MarketStatus status;
}
```

## Optional 使用方式

```java
// PASS: find* 方法回傳 Optional
// [SPRING]
Optional<Market> market = marketRepository.findBySlug(slug);

// [QUARKUS] Panache
Optional<Market> market = Market.find("slug", slug).firstResultOptional();

// PASS: 使用 map / flatMap，避免直接 get()
return market
    .map(MarketResponse::from)
    .orElseThrow(() -> new EntityNotFoundException("Market not found"));
```

## Streams 最佳實務

```java
// PASS: Streams 適合用於資料轉換，pipeline 應保持簡短
List<String> names = markets.stream()
    .map(Market::name)
    .filter(Objects::nonNull)
    .toList();

// FAIL: 避免複雜巢狀 streams；可讀性不足時改用 loop
```

## 依賴注入

```java
// PASS: [SPRING] Constructor injection，優先於 field 上使用 @Autowired
@Service
public class MarketService {
  private final MarketRepository marketRepository;

  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// PASS: [QUARKUS] Constructor injection
@ApplicationScoped
public class MarketService {
  private final MarketRepository marketRepository;

  @Inject
  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// PASS: [QUARKUS] Package-private field injection 可接受，可避免 proxy 問題
@ApplicationScoped
public class MarketService {
  @Inject
  MarketRepository marketRepository;
}

// FAIL: [SPRING] 避免使用 @Autowired field injection
@Autowired
private MarketRepository marketRepository; // 改用 constructor injection

// FAIL: [QUARKUS] 需要 interception 或 lazy init 時，不使用 @Singleton
@Singleton // non-proxyable，改用 @ApplicationScoped
public class MarketService {}
```

## Reactive 模式 [QUARKUS]

```java
// PASS: Reactive endpoint 回傳 Uni / Multi
@GET
@Path("/{slug}")
public Uni<Market> findBySlug(@PathParam("slug") String slug) {
  return Market.find("slug", slug)
      .<Market>firstResult()
      .onItem().ifNull().failWith(() -> new MarketNotFoundException(slug));
}

// PASS: 使用 non-blocking pipeline 組合流程
public Uni<OrderConfirmation> placeOrder(OrderRequest req) {
  return validateOrder(req)
      .chain(valid -> persistOrder(valid))
      .chain(order -> notifyFulfillment(order));
}

// FAIL: 不要在 Uni / Multi pipeline 中執行 blocking call
public Uni<Market> find(String slug) {
  Market m = Market.find("slug", slug).firstResult(); // BLOCKING，會破壞 event loop
  return Uni.createFrom().item(m);
}

// FAIL: 避免對 shared Uni 重複 subscribe
Uni<Market> shared = fetchMarket(slug);
shared.subscribe().with(m -> log(m));
shared.subscribe().with(m -> cache(m)); // double subscribe，應使用 Uni.memoize()
```

## 例外處理

* Domain error 使用 unchecked exception；technical exception 應包裝並補上上下文
* 建立 domain-specific exception，例如 `MarketNotFoundException`
* 避免寬泛地 `catch (Exception ex)`，除非會集中重新拋出或記錄

```java
throw new MarketNotFoundException(slug);
```

### 集中式例外處理

```java
// [SPRING]
@RestControllerAdvice
public class GlobalExceptionHandler {
  @ExceptionHandler(MarketNotFoundException.class)
  public ResponseEntity<ErrorResponse> handle(MarketNotFoundException ex) {
    return ResponseEntity.status(404).body(ErrorResponse.from(ex));
  }
}

// [QUARKUS] 選項 A：ExceptionMapper
@Provider
public class MarketNotFoundMapper implements ExceptionMapper<MarketNotFoundException> {
  @Override
  public Response toResponse(MarketNotFoundException ex) {
    return Response.status(404).entity(ErrorResponse.from(ex)).build();
  }
}

// [QUARKUS] 選項 B：@ServerExceptionMapper（RESTEasy Reactive）
@ServerExceptionMapper
public RestResponse<ErrorResponse> handle(MarketNotFoundException ex) {
  return RestResponse.status(Status.NOT_FOUND, ErrorResponse.from(ex));
}
```

## 泛型與型別安全

* 避免 raw types；明確宣告 generic parameters
* 可重用工具方法優先使用 bounded generics

```java
public <T extends Identifiable> Map<Long, T> indexById(Collection<T> items) { ... }
```

## 專案結構

### [SPRING] Maven / Gradle

```text
src/main/java/com/example/app/
  config/
  controller/
  service/
  repository/
  domain/
  dto/
  util/
src/main/resources/
  application.yml
src/test/java/... (mirrors main)
```

### [QUARKUS] Maven / Gradle

```text
src/main/java/com/example/app/
  config/              # @ConfigMapping、@ConfigProperty beans、Producers
  resource/            # JAX-RS resources，不使用 "controller"
  service/
  repository/          # PanacheRepository implementations；若未使用 active record
  domain/              # JPA / Panache entities、MongoDB entities
  dto/
  util/
  mapper/              # MapStruct mappers；若有使用
src/main/resources/
  application.properties   # Quarkus 慣例；YAML 可搭配 quarkus-config-yaml
  import.sql               # Hibernate dev / test 自動匯入資料
src/test/java/... (mirrors main)
```

## 格式與風格

* 依專案標準一致使用 2 或 4 個空格
* 每個檔案只放一個 public top-level type
* 方法保持短小且聚焦；必要時抽出 helper
* 成員排序：constants、fields、constructors、public methods、protected、private

## 應避免的 Code Smells

* 過長參數列表 → 改用 DTO / builder
* 過深巢狀結構 → 使用 early return
* Magic numbers → 改為具名常數
* Static mutable state → 優先使用 dependency injection
* Silent catch blocks → 記錄並處理，或重新拋出
* **[QUARKUS]**：需要 `@ApplicationScoped` 時誤用 `@Singleton`，會破壞 proxying 與 interception
* **[QUARKUS]**：混用 `quarkus-resteasy-reactive` 與 `quarkus-resteasy` classic，應選定一種 stack
* **[QUARKUS]**：同一個 bounded context 同時混用 Panache active-record 與 repository pattern，應二擇一

## 日誌

```java
// [SPRING] SLF4J
private static final Logger log = LoggerFactory.getLogger(MarketService.class);
log.info("fetch_market slug={}", slug);
log.error("failed_fetch_market slug={}", slug, ex);

// [QUARKUS] JBoss Logging，預設支援 build-time zero-cost
private static final Logger log = Logger.getLogger(MarketService.class);
log.infof("fetch_market slug=%s", slug);
log.errorf(ex, "failed_fetch_market slug=%s", slug);

// [QUARKUS] 替代方案：使用 @Inject 簡化 logging
@Inject
Logger log; // CDI-injected，作用域對應宣告的 class
```

## Null 處理

* 只有無法避免時才接受 `@Nullable`；其他情況使用 `@NonNull`
* 對輸入使用 Bean Validation，例如 `@NotNull`、`@NotBlank`
* **[QUARKUS]**：在 `@BeanParam`、`@RestForm` 與 request body parameters 上套用 `@Valid`

## 設定

```java
// [SPRING] @ConfigurationProperties
@ConfigurationProperties(prefix = "market")
public record MarketProperties(int maxPageSize, Duration cacheTtl) {}

// [QUARKUS] @ConfigMapping，type-safe，build-time validated
@ConfigMapping(prefix = "market")
public interface MarketConfig {
  int maxPageSize();
  Duration cacheTtl();
}

// [QUARKUS] 使用 @ConfigProperty 注入簡單值
@ConfigProperty(name = "market.max-page-size", defaultValue = "100")
int maxPageSize;
```

## 測試要求

### 共用

* 使用 JUnit 5 + AssertJ 撰寫 fluent assertions
* 使用 Mockito 進行 mocking；盡量避免 partial mocks
* 測試應具備可重現性，避免隱藏式 sleep

### [SPRING]

* 使用 `@WebMvcTest` 測試 controller slice，使用 `@DataJpaTest` 測試 repository slice
* `@SpringBootTest` 保留給完整 integration test
* 使用 `@MockBean` 替換 Spring context 中的 bean

### [QUARKUS]

* Unit test 使用純 JUnit 5 + Mockito，不使用 `@QuarkusTest`
* `@QuarkusTest` 保留給 CDI integration test
* 使用 `@InjectMock` 替換 integration test 中的 CDI bean
* Database / Kafka / Redis 優先使用 Dev Services；Dev Services 足夠時避免手動設定 Testcontainers
* 使用 `@QuarkusTestResource` 管理自訂外部服務生命週期

```java
// [SPRING] Controller test
@WebMvcTest(MarketController.class)
class MarketControllerTest {
  @Autowired MockMvc mockMvc;
  @MockBean MarketService marketService;
}

// [QUARKUS] Integration test
@QuarkusTest
class MarketResourceTest {
  @InjectMock
  MarketService marketService;

  @Test
  void should_return_404_when_market_not_found() {
    given().when().get("/markets/unknown").then().statusCode(404);
  }
}

// [QUARKUS] Unit test，不使用 CDI，不使用 @QuarkusTest
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository marketRepository;
  @InjectMocks MarketService marketService;
}
```

**記住**：程式碼應具備明確意圖、型別安全與可觀測性。除非已有證據證明需要微優化，否則優先追求可維護性。
