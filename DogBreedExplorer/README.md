# 🐕 DogBreedExplorer

> Aplicação iOS desenvolvida como teste técnico para explorar raças de cães

## 📱 Visão Geral

App iOS nativo em SwiftUI que consome a Dog CEO API para listar raças de cães e exibir detalhes com imagens.

### Funcionalidades
- Lista de raças com informações básicas
- Tela de detalhes com galeria de imagens
- Pull-to-refresh e estados de loading/erro
- Cache de imagens para performance

## 🚀 Execução

### Pré-requisitos
- macOS 12.0+, Xcode 14.0+, iOS 15.0+

### Comandos
git clone <repository-url>
cd DogBreedExplorer
open DogBreedExplorer.xcodeproj
Cmd + R

### Testes
Cmd + U
# ou
xcodebuild test -scheme DogBreedExplorer -destination 'platform=iOS Simulator,name=iPhone 14 Pro'

## 🏗️ Arquitetura

### Clean Architecture + MVVM
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  ┌─────────────┐  ┌─────────────┐  │
│  │    Views    │  │ ViewModels  │  │
│  └─────────────┘  └─────────────┘  │
├─────────────────────────────────────┤
│           Domain Layer              │
│  ┌─────────────┐  ┌─────────────┐  │
│  │   Models    │  │ Repositories│  │
│  └─────────────┘  └─────────────┘  │
├─────────────────────────────────────┤
│        Infrastructure Layer        │
│  ┌─────────────┐  ┌─────────────┐  │
│  │   Network   │  │    Cache    │  │
│  └─────────────┘  └─────────────┘  │
└─────────────────────────────────────┘

### Decisões Técnicas

**SwiftUI + Combine**: Interface declarativa e estado reativo
**Async/Await**: Programação assíncrona moderna
**Repository Pattern**: Abstração para testabilidade
**State Management**: Enums type-safe para estados

## 🧪 Testes

### Cobertura
- **Unitários**: ViewModels, Services, Models (6 arquivos)
- **UI**: Fluxo List → Detail → Back
- **Mocks**: Simulação de dependências

### Arquivos
DogBreedExplorerTests/
├── DogBreedExplorerTests.swift          # ViewModel principal
├── BreedDetailViewModelTests.swift      # ViewModel detalhes
├── NetworkServiceTests.swift            # Serviço rede
├── ImageCacheServiceTests.swift         # Cache imagens
├── BreedRepositoryTests.swift           # Repository
├── ModelTests.swift                     # Modelos
└── TestHelpers.swift                    # Utilitários

## 📊 Qualidade

### Padrões
- SOLID Principles aplicados
- Clean Code (funções pequenas)
- MVVM com separação clara
- Protocol-oriented programming

### Performance
- Cache: 100 imagens, 50MB limite
- Task cancellation para operações async
- Memory management automático

## 🚀 Melhorias Futuras (SE TIVESSE MAIS TEMPO)

### **1. Modo Offline**
**Por que**: Usuários precisam acessar sem internet
**Como**: Core Data + sincronização automática
**Impacto**: Maior disponibilidade

### **2. Busca e Filtros**
**Por que**: Lista de 100+ raças difícil de navegar
**Como**: SearchBar + filtros por características
**Impacto**: Navegação mais eficiente

### **3. Testes de Performance**
**Por que**: Garantir estabilidade com muitos dados
**Como**: XCTMetric para medir tempo/memória
**Impacto**: Qualidade em produção

### **4. Acessibilidade**
**Por que**: App deve ser acessível a todos
**Como**: VoiceOver + Dynamic Type
**Impacto**: Inclusividade

## 🎯 Critérios Atendidos

### ✅ Funcionalidades
- [x] Lista de itens da API
- [x] Informações básicas e detalhadas
- [x] Estados de loading e erro
- [x] Pull-to-refresh
- [x] Navegação entre telas

### ✅ Arquitetura
- [x] Clean Architecture implementada
- [x] Separação clara de responsabilidades
- [x] Padrões de design aplicados

### ✅ Boas Práticas
- [x] State management moderno
- [x] Error handling robusto
- [x] Código limpo e organizado
- [x] Testes abrangentes

---

# 🐕 DogBreedExplorer

> iOS application developed as a technical test to explore dog breeds

## 📱 Overview

Native iOS app in SwiftUI that consumes Dog CEO API to list dog breeds and display details with images.

### Features
- Breed list with basic information
- Detail screen with image gallery
- Pull-to-refresh and loading/error states
- Image cache for performance

## 🚀 Execution

### Prerequisites
- macOS 12.0+, Xcode 14.0+, iOS 15.0+

### Commands
git clone <repository-url>
cd DogBreedExplorer
open DogBreedExplorer.xcodeproj
Cmd + R

### Tests
Cmd + U
# or
xcodebuild test -scheme DogBreedExplorer -destination 'platform=iOS Simulator,name=iPhone 14 Pro'

## 🏗️ Architecture

### Clean Architecture + MVVM
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  ┌─────────────┐  ┌─────────────┐  │
│  │    Views    │  │ ViewModels  │  │
│  └─────────────┘  └─────────────┘  │
├─────────────────────────────────────┤
│           Domain Layer              │
│  ┌─────────────┐  ┌─────────────┐  │
│  │   Models    │  │ Repositories│  │
│  └─────────────┘  └─────────────┘  │
├─────────────────────────────────────┤
│        Infrastructure Layer        │
│  ┌─────────────┐  ┌─────────────┐  │
│  │   Network   │  │    Cache    │  │
│  └─────────────┘  └─────────────┘  │
└─────────────────────────────────────┘

### Technical Decisions

**SwiftUI + Combine**: Declarative interface and reactive state
**Async/Await**: Modern asynchronous programming
**Repository Pattern**: Abstraction for testability
**State Management**: Type-safe enums for states

## 🧪 Testing

### Coverage
- **Unit**: ViewModels, Services, Models (6 files)
- **UI**: List → Detail → Back flow
- **Mocks**: Dependency simulation

### Files
DogBreedExplorerTests/
├── DogBreedExplorerTests.swift          # Main ViewModel
├── BreedDetailViewModelTests.swift      # Detail ViewModel
├── NetworkServiceTests.swift            # Network service
├── ImageCacheServiceTests.swift         # Image cache
├── BreedRepositoryTests.swift           # Repository
├── ModelTests.swift                     # Models
└── TestHelpers.swift                    # Utilities

## 📊 Quality

### Patterns
- SOLID Principles applied
- Clean Code (small functions)
- MVVM with clear separation
- Protocol-oriented programming

### Performance
- Cache: 100 images, 50MB limit
- Task cancellation for async operations
- Automatic memory management

## 🚀 Future Improvements (WITH MORE TIME)

### **1. Offline Mode**
**Why**: Users need access without internet
**How**: Core Data + automatic sync
**Impact**: Better availability

### **2. Search and Filters**
**Why**: 100+ breeds list hard to navigate
**How**: SearchBar + characteristic filters
**Impact**: More efficient navigation

### **3. Performance Testing**
**Why**: Ensure stability with large datasets
**How**: XCTMetric to measure time/memory
**Impact**: Production quality

### **4. Accessibility**
**Why**: App should be accessible to all
**How**: VoiceOver + Dynamic Type
**Impact**: Inclusivity

## 🎯 Criteria Met

### ✅ Features
- [x] API item list
- [x] Basic and detailed information
- [x] Loading and error states
- [x] Pull-to-refresh
- [x] Screen navigation

### ✅ Architecture
- [x] Clean Architecture implemented
- [x] Clear separation of responsibilities
- [x] Design patterns applied

### ✅ Best Practices
- [x] Modern state management
- [x] Robust error handling
- [x] Clean and organized code
- [x] Comprehensive tests

---