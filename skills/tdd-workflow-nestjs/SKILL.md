---
name: tdd-workflow-nestjs
description: Use this skill when working on NestJS projects — writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests tailored for NestJS.
---

# Test-Driven Development Workflow for NestJS

This skill ensures all NestJS backend development follows TDD principles with comprehensive test coverage.

## When to Activate

- Writing new NestJS modules, services, controllers, or guards
- Fixing bugs in NestJS applications
- Refactoring existing NestJS code
- Adding REST or GraphQL API endpoints
- Creating middleware, interceptors, pipes, or filters
- Integrating with databases (TypeORM, Prisma, Mongoose, etc.)
- Implementing authentication/authorization logic

## When NOT to Activate

- Frontend development (Vue, React, Angular, etc.)
- Non-NestJS Node.js projects
- Static sites, CLI tools, or standalone scripts

## Core Principles

### 1. Tests BEFORE Code
ALWAYS write tests first, then implement code to make tests pass.

### 2. Coverage Requirements
- Minimum 80% coverage (unit + integration + E2E)
- All edge cases covered
- Error scenarios tested
- Boundary conditions verified

### 3. Test Types

#### Unit Tests
- Services, providers, and utility functions
- Guards, pipes, interceptors, and filters
- Pure business logic and domain models
- Custom decorators

#### Integration Tests
- Controller endpoints with mocked services
- Database repository operations
- Module composition and dependency injection
- Middleware chains

#### E2E Tests
- Full HTTP request/response cycles via `supertest`
- Authentication and authorization flows
- Complete CRUD workflows
- Error handling and validation pipelines

## TDD Workflow Steps

### Step 1: Write User Stories
```
As a [role], I want to [action], so that [benefit]

Example:
As an API consumer, I want to search for products by keyword,
so that I can find relevant items without knowing exact names.
```

### Step 2: Generate Test Cases
For each user story, create comprehensive test cases:

```typescript
describe('ProductService', () => {
  it('should return matching products for a keyword query', async () => {
    // Test implementation
  });

  it('should return an empty array when no products match', async () => {
    // Test edge case
  });

  it('should throw BadRequestException for empty query string', async () => {
    // Test validation
  });

  it('should paginate results with default page size', async () => {
    // Test pagination logic
  });
});
```

### Step 3: Run Tests (They Should Fail)
```bash
npm run test
# Tests should fail — we haven't implemented yet
```

### Step 4: Implement Code
Write minimal code to make tests pass:

```typescript
@Injectable()
export class ProductService {
  constructor(
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
  ) {}

  async search(query: string, page = 1, limit = 20): Promise<Product[]> {
    // Implementation here
  }
}
```

### Step 5: Run Tests Again
```bash
npm run test
# Tests should now pass
```

### Step 6: Refactor
Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Optimize queries
- Enhance readability

### Step 7: Verify Coverage
```bash
npm run test:cov
# Verify 80%+ coverage achieved
```

## Testing Patterns

### Unit Test Pattern — Service
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductService } from './product.service';
import { Product } from './entities/product.entity';
import { BadRequestException, NotFoundException } from '@nestjs/common';

describe('ProductService', () => {
  let service: ProductService;
  let repository: jest.Mocked<Repository<Product>>;

  const mockProducts: Product[] = [
    { id: 1, name: 'Wireless Mouse', price: 29.99 } as Product,
    { id: 2, name: 'Wireless Keyboard', price: 49.99 } as Product,
  ];

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProductService,
        {
          provide: getRepositoryToken(Product),
          useValue: {
            find: jest.fn(),
            findOne: jest.fn(),
            save: jest.fn(),
            delete: jest.fn(),
            createQueryBuilder: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<ProductService>(ProductService);
    repository = module.get(getRepositoryToken(Product));
  });

  describe('search', () => {
    it('should return matching products for a keyword query', async () => {
      repository.find.mockResolvedValue(mockProducts);

      const result = await service.search('wireless');

      expect(result).toEqual(mockProducts);
      expect(repository.find).toHaveBeenCalledTimes(1);
    });

    it('should throw BadRequestException for empty query', async () => {
      await expect(service.search('')).rejects.toThrow(BadRequestException);
    });
  });

  describe('findOne', () => {
    it('should return a product by id', async () => {
      repository.findOne.mockResolvedValue(mockProducts[0]);

      const result = await service.findOne(1);

      expect(result).toEqual(mockProducts[0]);
    });

    it('should throw NotFoundException when product does not exist', async () => {
      repository.findOne.mockResolvedValue(null);

      await expect(service.findOne(999)).rejects.toThrow(NotFoundException);
    });
  });
});
```

### Unit Test Pattern — Guard
```typescript
import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RolesGuard } from './roles.guard';

describe('RolesGuard', () => {
  let guard: RolesGuard;
  let reflector: jest.Mocked<Reflector>;

  beforeEach(() => {
    reflector = { getAllAndOverride: jest.fn() } as any;
    guard = new RolesGuard(reflector);
  });

  const mockExecutionContext = (userRole: string): ExecutionContext =>
    ({
      getHandler: jest.fn(),
      getClass: jest.fn(),
      switchToHttp: () => ({
        getRequest: () => ({ user: { role: userRole } }),
      }),
    }) as unknown as ExecutionContext;

  it('should allow access when no roles are required', () => {
    reflector.getAllAndOverride.mockReturnValue(undefined);

    const result = guard.canActivate(mockExecutionContext('user'));

    expect(result).toBe(true);
  });

  it('should allow access when user has the required role', () => {
    reflector.getAllAndOverride.mockReturnValue(['admin']);

    const result = guard.canActivate(mockExecutionContext('admin'));

    expect(result).toBe(true);
  });

  it('should deny access when user lacks the required role', () => {
    reflector.getAllAndOverride.mockReturnValue(['admin']);

    expect(() => guard.canActivate(mockExecutionContext('user'))).toThrow(
      UnauthorizedException,
    );
  });
});
```

### Integration Test Pattern — Controller
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { ProductController } from './product.controller';
import { ProductService } from './product.service';
import { CreateProductDto } from './dto/create-product.dto';

describe('ProductController', () => {
  let controller: ProductController;
  let service: jest.Mocked<ProductService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ProductController],
      providers: [
        {
          provide: ProductService,
          useValue: {
            findAll: jest.fn(),
            findOne: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
            remove: jest.fn(),
            search: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<ProductController>(ProductController);
    service = module.get(ProductService);
  });

  describe('POST /products', () => {
    it('should create and return a new product', async () => {
      const dto: CreateProductDto = { name: 'New Product', price: 19.99 };
      const created = { id: 1, ...dto };

      service.create.mockResolvedValue(created as any);

      const result = await controller.create(dto);

      expect(result).toEqual(created);
      expect(service.create).toHaveBeenCalledWith(dto);
    });
  });

  describe('GET /products/:id', () => {
    it('should return the product for a valid id', async () => {
      const product = { id: 1, name: 'Mouse', price: 29.99 };
      service.findOne.mockResolvedValue(product as any);

      const result = await controller.findOne(1);

      expect(result).toEqual(product);
    });
  });
});
```

### E2E Test Pattern (supertest)
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('ProductController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('GET /products', () => {
    it('should return 200 with an array of products', () => {
      return request(app.getHttpServer())
        .get('/products')
        .expect(200)
        .expect((res) => {
          expect(Array.isArray(res.body)).toBe(true);
        });
    });
  });

  describe('POST /products', () => {
    it('should return 201 when creating a valid product', () => {
      return request(app.getHttpServer())
        .post('/products')
        .send({ name: 'E2E Product', price: 9.99 })
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('id');
          expect(res.body.name).toBe('E2E Product');
        });
    });

    it('should return 400 for invalid payload', () => {
      return request(app.getHttpServer())
        .post('/products')
        .send({ name: '' })
        .expect(400);
    });
  });

  describe('GET /products/:id', () => {
    it('should return 404 for non-existent product', () => {
      return request(app.getHttpServer())
        .get('/products/999999')
        .expect(404);
    });
  });

  describe('Authentication flow', () => {
    let accessToken: string;

    it('should login and receive a JWT token', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'test@example.com', password: 'password123' })
        .expect(200);

      accessToken = res.body.accessToken;
      expect(accessToken).toBeDefined();
    });

    it('should access a protected route with valid token', () => {
      return request(app.getHttpServer())
        .get('/products/admin')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
    });

    it('should reject access without a token', () => {
      return request(app.getHttpServer())
        .get('/products/admin')
        .expect(401);
    });
  });
});
```

## Test File Organization

```
src/
├── products/
│   ├── dto/
│   │   ├── create-product.dto.ts
│   │   └── update-product.dto.ts
│   ├── entities/
│   │   └── product.entity.ts
│   ├── product.controller.ts
│   ├── product.controller.spec.ts    # Controller integration tests
│   ├── product.service.ts
│   ├── product.service.spec.ts       # Service unit tests
│   └── product.module.ts
├── auth/
│   ├── guards/
│   │   ├── roles.guard.ts
│   │   └── roles.guard.spec.ts       # Guard unit tests
│   ├── strategies/
│   │   ├── jwt.strategy.ts
│   │   └── jwt.strategy.spec.ts
│   ├── auth.service.ts
│   ├── auth.service.spec.ts
│   └── auth.module.ts
├── common/
│   ├── pipes/
│   │   ├── parse-int.pipe.ts
│   │   └── parse-int.pipe.spec.ts
│   ├── interceptors/
│   │   ├── logging.interceptor.ts
│   │   └── logging.interceptor.spec.ts
│   └── filters/
│       ├── http-exception.filter.ts
│       └── http-exception.filter.spec.ts
└── test/
    ├── app.e2e-spec.ts                # E2E tests
    ├── products.e2e-spec.ts
    ├── auth.e2e-spec.ts
    └── jest-e2e.json                  # E2E Jest config
```

## Mocking External Services

### TypeORM Repository Mock
```typescript
export const mockRepository = <T>() => ({
  find: jest.fn(),
  findOne: jest.fn(),
  findOneBy: jest.fn(),
  save: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
  createQueryBuilder: jest.fn(() => ({
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    take: jest.fn().mockReturnThis(),
    getMany: jest.fn(),
    getOne: jest.fn(),
    getCount: jest.fn(),
  })),
});
```

### Prisma Service Mock
```typescript
export const mockPrismaService = {
  product: {
    findMany: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    count: jest.fn(),
  },
  user: {
    findMany: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
  },
  $transaction: jest.fn((cb) => cb(mockPrismaService)),
};
```

### HttpService (Axios) Mock
```typescript
import { of, throwError } from 'rxjs';

export const mockHttpService = {
  get: jest.fn(() => of({ data: { result: 'ok' }, status: 200 })),
  post: jest.fn(() => of({ data: { id: 1 }, status: 201 })),
  put: jest.fn(),
  delete: jest.fn(),
};
```

### Redis (Cache) Mock
```typescript
export const mockCacheManager = {
  get: jest.fn(),
  set: jest.fn(),
  del: jest.fn(),
  reset: jest.fn(),
};

// Usage in TestingModule:
// { provide: CACHE_MANAGER, useValue: mockCacheManager }
```

### ConfigService Mock
```typescript
export const mockConfigService = {
  get: jest.fn((key: string) => {
    const config: Record<string, string> = {
      DATABASE_URL: 'postgres://test:test@localhost/test',
      JWT_SECRET: 'test-secret',
      REDIS_HOST: 'localhost',
    };
    return config[key];
  }),
};
```

## Test Coverage Verification

### Run Coverage Report
```bash
npm run test:cov
```

### Jest Configuration (package.json)
```json
{
  "jest": {
    "moduleFileExtensions": ["js", "json", "ts"],
    "rootDir": "src",
    "testRegex": ".*\\.spec\\.ts$",
    "transform": {
      "^.+\\.(t|j)s$": "ts-jest"
    },
    "collectCoverageFrom": [
      "**/*.(t|j)s",
      "!**/*.module.ts",
      "!**/main.ts",
      "!**/*.dto.ts",
      "!**/*.entity.ts",
      "!**/*.interface.ts"
    ],
    "coverageDirectory": "../coverage",
    "coverageThreshold": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    },
    "testEnvironment": "node"
  }
}
```

### E2E Jest Configuration (test/jest-e2e.json)
```json
{
  "moduleFileExtensions": ["js", "json", "ts"],
  "rootDir": ".",
  "testEnvironment": "node",
  "testRegex": ".e2e-spec.ts$",
  "transform": {
    "^.+\\.(t|j)s$": "ts-jest"
  }
}
```

## Common Testing Mistakes to Avoid

### ❌ WRONG: Not Using NestJS Testing Utilities
```typescript
// Manually instantiating — skips DI, pipes, guards
const service = new ProductService(new Repository());
```

### ✅ CORRECT: Use `Test.createTestingModule`
```typescript
const module = await Test.createTestingModule({
  providers: [ProductService, { provide: getRepositoryToken(Product), useValue: mockRepo }],
}).compile();
const service = module.get<ProductService>(ProductService);
```

### ❌ WRONG: Testing Internal Implementation
```typescript
// Checking private method calls
expect(service['buildQuery']).toHaveBeenCalled();
```

### ✅ CORRECT: Test Public API and Behavior
```typescript
// Test the outcome
const result = await service.search('keyboard');
expect(result).toHaveLength(2);
```

### ❌ WRONG: Shared Mutable State Between Tests
```typescript
let createdId: number;
it('creates a product', async () => { createdId = ...; });
it('updates the product', async () => { /* uses createdId */ });
```

### ✅ CORRECT: Independent Tests
```typescript
it('creates a product', async () => {
  const product = await createTestProduct();
  expect(product.id).toBeDefined();
});

it('updates a product', async () => {
  const product = await createTestProduct();
  const updated = await service.update(product.id, { name: 'Updated' });
  expect(updated.name).toBe('Updated');
});
```

### ❌ WRONG: Not Cleaning Up in E2E Tests
```typescript
// Database fills up across test runs
it('creates a product', () => { /* no cleanup */ });
```

### ✅ CORRECT: Setup and Teardown
```typescript
beforeEach(async () => {
  await dataSource.synchronize(true); // reset DB before each test
});

afterAll(async () => {
  await app.close();
});
```

## Continuous Testing

### Watch Mode During Development
```bash
npm run test:watch
# Tests run automatically on file changes
```

### Pre-Commit Hook
```bash
# Runs before every commit
npm run test && npm run lint
```

### CI/CD Integration
```yaml
# GitHub Actions
- name: Run Unit & Integration Tests
  run: npm run test -- --coverage

- name: Run E2E Tests
  run: npm run test:e2e

- name: Upload Coverage
  uses: codecov/codecov-action@v3
```

## Best Practices

1. **Write Tests First** — always TDD
2. **One Assertion Per Test** — focus on a single behavior
3. **Descriptive Test Names** — explain what is being tested
4. **Arrange-Act-Assert** — clear test structure
5. **Use `Test.createTestingModule`** — leverage NestJS DI in tests
6. **Mock External Dependencies** — isolate unit tests from DB, HTTP, cache
7. **Test Edge Cases** — null, undefined, empty, large payloads, invalid types
8. **Test Error Paths** — not just happy paths
9. **Keep Tests Fast** — unit tests < 50ms each
10. **Clean Up After Tests** — close app, reset DB, clear mocks
11. **Review Test Scripts** — ensure `package.json` contains correct test scripts

## Success Metrics

- 80%+ code coverage achieved
- All tests passing (green)
- No skipped or disabled tests
- Fast test execution (< 30s for unit tests)
- E2E tests cover critical API flows and auth scenarios
- Tests catch bugs before production

---

**Remember**: Tests are not optional. They are the safety net that enables confident refactoring, rapid development, and production reliability.