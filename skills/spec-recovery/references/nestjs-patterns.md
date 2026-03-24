# NestJS / Node.js 後端萃取模式

偵測到 NestJS 專案時（package.json 含 `@nestjs/core`），或一般 Node.js/Express 後端時載入此文件。

---

## 後端分析順序

```
Module 定義（*.module.ts）→ Controller（路由 + 裝飾器）
→ Service（業務邏輯）→ Entity / Schema（資料模型）
→ Guard / Middleware（橫切關注點）→ 排程任務 → 環境變數
```

---

## 萃取 API 清單

### NestJS

從 Controller 裝飾器萃取：

```typescript
@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrderController {
  @Get()
  @Roles('admin', 'editor')
  findAll(@Query() query: FindOrderDto) { ... }

  @Post()
  @Roles('admin')
  create(@Body() dto: CreateOrderDto) { ... }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateOrderDto) { ... }
}
```

可萃取：HTTP method、路徑、認證、角色、request DTO、response 型別。

### Express / Fastify

從路由定義萃取：

```typescript
router.get('/orders', authMiddleware, orderController.findAll);
router.post('/orders', authMiddleware, adminOnly, orderController.create);
```

---

## 萃取資料模型

### TypeORM

```typescript
@Entity()
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100 })
  customerName: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @Column({ type: 'enum', enum: OrderStatus, default: OrderStatus.DRAFT })
  status: OrderStatus;

  @ManyToOne(() => User, (user) => user.orders)
  createdBy: User;

  @CreateDateColumn()
  createdAt: Date;

  @DeleteDateColumn() // 軟刪除
  deletedAt: Date;
}
```

### Prisma

```prisma
model Order {
  id           String      @id @default(uuid())
  customerName String      @db.VarChar(100)
  amount       Decimal     @db.Decimal(10, 2)
  status       OrderStatus @default(DRAFT)
  createdBy    User        @relation(fields: [createdById], references: [id])
  createdAt    DateTime    @default(now())
  deletedAt    DateTime?
}
```

### Mongoose

```typescript
const OrderSchema = new Schema({
  customerName: { type: String, required: true, maxlength: 100 },
  amount: { type: Number, required: true, min: 0 },
  status: { type: String, enum: ['draft', 'submitted', 'approved'], default: 'draft' },
});
```

---

## 萃取驗證規則

### class-validator（NestJS DTO）

```typescript
export class CreateOrderDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  customerName: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  amount: number;

  @IsEnum(OrderStatus)
  @IsOptional()
  status?: OrderStatus;
}
```

### Joi / Zod

```typescript
const createOrderSchema = Joi.object({
  customerName: Joi.string().required().max(100),
  amount: Joi.number().required().positive().precision(2),
});
```

---

## 萃取橫切關注點

### Guard / Middleware

```typescript
// 搜尋 @UseGuards 了解每個 route 的認證需求
@UseGuards(JwtAuthGuard)        // 需登入
@UseGuards(RolesGuard)          // 需特定角色
@UseInterceptors(LoggingInterceptor)  // 有日誌記錄
@UsePipes(ValidationPipe)       // 有輸入驗證
```

### Exception Filter

```typescript
// 全域或模組級的錯誤處理策略
@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) { ... }
}
```

---

## 萃取副作用

搜尋以下模式：

```typescript
// Event emitter
this.eventEmitter.emit('order.created', order);

// Message queue
this.amqpConnection.publish('exchange', 'routing.key', payload);

// 排程任務
@Cron('0 0 * * *')  // 每日午夜
handleDailyCleanup() { ... }

// Transaction
await this.dataSource.transaction(async (manager) => { ... });
// ⚠️ 資料一致性邊界

// 外部 API 呼叫
await this.httpService.post('https://external-api.com/webhook', data);
```

---

## 萃取隱性規則（後端特有）

```typescript
// 模式：軟刪除
@DeleteDateColumn()
deletedAt: Date;
// ⚠️ 使用軟刪除，findAll 可能需要加 where deletedAt IS NULL

// 模式：環境變數依賴
const limit = process.env.MAX_EXPORT_ROWS || '10000';
// ⚠️ 匯出上限可由環境變數配置，預設 10000

// 模式：隱含的排序
return this.repo.find({ order: { createdAt: 'DESC' } });
// ⚠️ 預設按建立時間倒序

// 模式：Transaction 邊界
await this.dataSource.transaction(async (manager) => {
  await manager.save(order);
  await manager.save(orderItems);
  await this.notificationService.send(order); // ← 在 transaction 內
});
// ⚠️ 通知發送在 transaction 內，如果通知失敗會 rollback 訂單
```
