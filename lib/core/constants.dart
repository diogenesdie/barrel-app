// =============================================================================
// constants.dart
//
// Constantes globais de configuração da aplicação.
// Contém endpoints da API REST, credenciais e chave de modo de comunicação.
//
// ATENÇÃO: Em produção, mover BEARER_TOKEN e PUBLIC_IP para variáveis de
// ambiente ou arquivo de configuração seguro (ex.: flutter_dotenv).
// =============================================================================

// ignore_for_file: constant_identifier_names

/// Token fixo de autenticação para requisições legadas (uso interno do servidor).
const BEARER_TOKEN = "d4f8a7e2-9b3c-4f6a-b5d1-7c9e1a0f2e8c";

/// IP público do servidor de backend Barrel.
const PUBLIC_IP = "192.140.33.83";

/// URL base da API REST para recursos autenticados (dispositivos, grupos, compartilhamentos).
const String BASE_API_URL = "https://barrel.app.br/api/api/v1";

/// URL base da API de autenticação (login, registro, refresh de token).
const String BASE_API_AUTH_URL = "https://barrel.app.br/api/auth/v1";

/// Chave do SharedPreferences que armazena o modo de comunicação selecionado
/// pelo usuário ('auto' usa HTTP local na mesma rede, ou MQTT remotamente).
const String COMM_KEY = "autoProtocol";
