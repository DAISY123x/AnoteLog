/**
 * @file ErrorCode.ets
 * @brief 应用统一错误码枚举
 * @description 按模块分组，便于问题定位
 */
export enum ErrorCode {
  // ==================== 数据库错误 (1xxx) ====================
  DB_INIT_FAILED = 1001,
  DB_QUERY_FAILED = 1002,
  DB_INSERT_FAILED = 1003,
  DB_UPDATE_FAILED = 1004,
  DB_DELETE_FAILED = 1005,

  // ==================== 网络错误 (2xxx) ====================
  NETWORK_UNAVAILABLE = 2001,
  HTTP_REQUEST_FAILED = 2002,
  HTTP_TIMEOUT = 2003,

  // ==================== 认证错误 (3xxx) ====================
  AUTH_NOT_LOGIN = 3001,
  AUTH_INVALID_TOKEN = 3002,
  AUTH_PERMISSION_DENIED = 3003,

  // ==================== 业务错误 (4xxx) ====================
  VALIDATION_FAILED = 4001,
  DUPLICATE_RESOURCE = 4002,
  RESOURCE_NOT_FOUND = 4003,

  // ==================== AI 服务错误 (5xxx) ====================
  AI_SERVICE_ERROR = 5001,
  AI_API_KEY_INVALID = 5002,
  AI_REQUEST_TIMEOUT = 5003,
}
