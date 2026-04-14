#!/bin/bash

MODULE="$1"
TARGET_DIR="$2"

if [ -z "$MODULE" ]; then
  echo "ERROR: debes pasar el nombre del modulo"
  exit 1
fi

if [ -z "$TARGET_DIR" ]; then
  echo "ERROR: no se recibió TARGET_DIR"
  exit 1
fi

# 🔹 Detectar lenguaje (Java o Kotlin)
if [[ "$TARGET_DIR" == *"/kotlin"* ]]; then
  LANG="kotlin"
  EXT="kt"
  SRC_ROOT="src/main/kotlin"
else
  LANG="java"
  EXT="java"
  SRC_ROOT="src/main/java"
fi

# 🔹 Obtener package dinámico
PKG_PATH=$(echo "$TARGET_DIR" | sed "s|.*$SRC_ROOT/||" | tr '/' '.')
FULL_PKG="$PKG_PATH.$MODULE"

# 🔹 Capitalizar nombre
CAP="$(tr '[:lower:]' '[:upper:]' <<< ${MODULE:0:1})${MODULE:1}"

BASE="$TARGET_DIR/$MODULE"

echo "🚀 Creando módulo: $MODULE"
echo "📦 Package: $FULL_PKG"
echo "💻 Lenguaje: $LANG"

# 🔹 Crear estructura
mkdir -p $BASE/application
mkdir -p $BASE/domain
mkdir -p $BASE/infrastructure/http
mkdir -p $BASE/infrastructure/persistence

# =====================================================
# ================== JAVA ==============================
# =====================================================
if [ "$LANG" = "java" ]; then

cat > $BASE/application/${CAP}CommandService.java << EOF
package $FULL_PKG.application;

import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ${CAP}CommandService {
    private final ${CAP}Repository ${MODULE}Repository;
}
EOF

cat > $BASE/application/${CAP}QueryService.java << EOF
package $FULL_PKG.application;

import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ${CAP}QueryService {
    private final ${CAP}Repository ${MODULE}Repository;
}
EOF

cat > $BASE/domain/${CAP}.java << EOF
package $FULL_PKG.domain;

import lombok.*;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class ${CAP} {
    private final UUID id;
}
EOF

cat > $BASE/domain/${CAP}Repository.java << EOF
package $FULL_PKG.domain;

import java.util.*;

public interface ${CAP}Repository {
    ${CAP} save(${CAP} entity);
    Optional<${CAP}> findById(UUID id);
    List<${CAP}> findAll();
    void deleteById(UUID id);
}
EOF

cat > $BASE/infrastructure/http/${CAP}Controller.java << EOF
package $FULL_PKG.infrastructure.http;

import org.springframework.web.bind.annotation.*;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/${MODULE}s")
@RequiredArgsConstructor
public class ${CAP}Controller {
    private final ${CAP}CommandService commandService;
    private final ${CAP}QueryService queryService;
}
EOF

cat > $BASE/infrastructure/persistence/${CAP}RepositoryImpl.java << EOF
package $FULL_PKG.infrastructure.persistence;

import $FULL_PKG.domain.*;
import org.springframework.stereotype.Repository;
import lombok.RequiredArgsConstructor;
import java.util.*;

@Repository
@RequiredArgsConstructor
public class ${CAP}RepositoryImpl implements ${CAP}Repository {

    private final JPAImpl${CAP}Repository jpaRepo;

    public ${CAP} save(${CAP} e){ return e; }
    public Optional<${CAP}> findById(UUID id){ return Optional.empty(); }
    public List<${CAP}> findAll(){ return List.of(); }
    public void deleteById(UUID id){}
}
EOF

cat > $BASE/infrastructure/persistence/JPAImpl${CAP}Repository.java << EOF
package $FULL_PKG.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface JPAImpl${CAP}Repository extends JpaRepository<Object, UUID> {}
EOF

fi

# =====================================================
# ================== KOTLIN ============================
# =====================================================
if [ "$LANG" = "kotlin" ]; then

cat > $BASE/application/${CAP}CommandService.kt << EOF
package $FULL_PKG.application

import org.springframework.stereotype.Service

@Service
class ${CAP}CommandService(
    private val ${MODULE}Repository: ${CAP}Repository
)
EOF

cat > $BASE/application/${CAP}QueryService.kt << EOF
package $FULL_PKG.application

import org.springframework.stereotype.Service

@Service
class ${CAP}QueryService(
    private val ${MODULE}Repository: ${CAP}Repository
)
EOF

cat > $BASE/domain/${CAP}.kt << EOF
package $FULL_PKG.domain

import java.util.UUID

data class ${CAP}(val id: UUID = UUID.randomUUID())
EOF

cat > $BASE/domain/${CAP}Repository.kt << EOF
package $FULL_PKG.domain

import java.util.UUID

interface ${CAP}Repository {
    fun save(${MODULE}: ${CAP}): ${CAP}
    fun findById(id: UUID): ${CAP}?
    fun findAll(): List<${CAP}>
    fun deleteById(id: UUID)
}
EOF

cat > $BASE/infrastructure/http/${CAP}Controller.kt << EOF
package $FULL_PKG.infrastructure.http

import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/${MODULE}s")
class ${CAP}Controller(
    private val commandService: ${CAP}CommandService,
    private val queryService: ${CAP}QueryService
)
EOF

cat > $BASE/infrastructure/persistence/${CAP}RepositoryImpl.kt << EOF
package $FULL_PKG.infrastructure.persistence

import $FULL_PKG.domain.*
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
class ${CAP}RepositoryImpl(
    private val jpaRepo: JPAImpl${CAP}Repository
) : ${CAP}Repository {

    override fun save(${MODULE}: ${CAP}) = ${MODULE}
    override fun findById(id: UUID): ${CAP}? = null
    override fun findAll() = emptyList<${CAP}>()
    override fun deleteById(id: UUID) {}
}
EOF

cat > $BASE/infrastructure/persistence/JPAImpl${CAP}Repository.kt << EOF
package $FULL_PKG.infrastructure.persistence

import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface JPAImpl${CAP}Repository : JpaRepository<Any, UUID>
EOF

fi

echo "✅ Módulo '$MODULE' creado correctamente en:"
echo "$BASE"
