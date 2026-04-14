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

# 🔹 Normalizar path (Windows → Unix)
NORMALIZED_PATH=$(echo "$TARGET_DIR" | tr '\\' '/')

# 🔹 Detectar lenguaje
if [[ "$NORMALIZED_PATH" == *"/src/main/kotlin/"* ]]; then
  LANG="kotlin"
  SRC_ROOT="src/main/kotlin"
elif [[ "$NORMALIZED_PATH" == *"/src/main/java/"* ]]; then
  LANG="java"
  SRC_ROOT="src/main/java"
else
  echo "⚠️ No se pudo detectar lenguaje, usando JAVA por defecto"
  LANG="java"
  SRC_ROOT="src/main/java"
fi

# 🔹 Naming correcto

# Clase (PascalCase)
CAP="$(tr '[:lower:]' '[:upper:]' <<< ${MODULE:0:1})${MODULE:1}"

# Variable / carpeta (camelCase)
VAR_NAME="$(tr '[:upper:]' '[:lower:]' <<< ${MODULE:0:1})${MODULE:1}"

MODULE_NAME="$VAR_NAME"

# 🔹 Package dinámico
PKG_PATH=$(echo "$NORMALIZED_PATH" | sed "s|.*$SRC_ROOT/||" | tr '/' '.')
FULL_PKG="$PKG_PATH.$MODULE_NAME"

BASE="$TARGET_DIR/$MODULE_NAME"

echo "🚀 Creando módulo: $MODULE_NAME"
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

import $FULL_PKG.domain.${CAP}Repository;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ${CAP}CommandService {

    private final ${CAP}Repository ${VAR_NAME}Repository;

}
EOF

cat > $BASE/application/${CAP}QueryService.java << EOF
package $FULL_PKG.application;

import $FULL_PKG.domain.${CAP}Repository;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ${CAP}QueryService {

    private final ${CAP}Repository ${VAR_NAME}Repository;

}
EOF

cat > $BASE/domain/${CAP}.java << EOF
package $FULL_PKG.domain;

import com.bbf.friday.bbf.back.shared.infrastructure.auditing.AuditableEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.*;

@Entity
@Table(name = "${MODULE_NAME}")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ${CAP} extends AuditableEntity {

    @Id
    private String id;

}
EOF

cat > $BASE/domain/${CAP}Repository.java << EOF
package $FULL_PKG.domain;

import org.springframework.data.domain.Page;
import java.util.Optional;

public interface ${CAP}Repository {

    Page<${CAP}> findAll();
    Optional<${CAP}> findById(String id);
    ${CAP} save(${CAP} ${VAR_NAME});

}
EOF

cat > $BASE/infrastructure/http/${CAP}Controller.java << EOF
package $FULL_PKG.infrastructure.http;

import $FULL_PKG.application.${CAP}CommandService;
import $FULL_PKG.application.${CAP}QueryService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/${MODULE_NAME}")
@RequiredArgsConstructor
public class ${CAP}Controller {

    private final ${CAP}CommandService ${VAR_NAME}CommandService;
    private final ${CAP}QueryService ${VAR_NAME}QueryService;

}
EOF

cat > $BASE/infrastructure/persistence/JPAImpl${CAP}Repository.java << EOF
package $FULL_PKG.infrastructure.persistence;

import $FULL_PKG.domain.${CAP};
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface JPAImpl${CAP}Repository extends JpaRepository<${CAP}, String>, JpaSpecificationExecutor<${CAP}> {

}
EOF

cat > $BASE/infrastructure/persistence/${CAP}RepositoryImpl.java << EOF
package $FULL_PKG.infrastructure.persistence;

import $FULL_PKG.domain.${CAP};
import $FULL_PKG.domain.${CAP}Repository;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ${CAP}RepositoryImpl implements ${CAP}Repository {

    private final JPAImpl${CAP}Repository jpaImpl${CAP}Repository;

    @Override
    public Page<${CAP}> findAll() {
        return Page.empty();
    }

    @Override
    public Optional<${CAP}> findById(String id) {
        return Optional.empty();
    }

    @Override
    public ${CAP} save(${CAP} ${VAR_NAME}) {
        return null;
    }
}
EOF

fi

# =====================================================
# ================== KOTLIN ============================
# =====================================================

if [ "$LANG" = "kotlin" ]; then

cat > $BASE/application/${CAP}CommandService.kt << EOF
package $FULL_PKG.application

import $FULL_PKG.domain.${CAP}Repository
import org.springframework.stereotype.Service

@Service
class ${CAP}CommandService(
    private val ${VAR_NAME}Repository: ${CAP}Repository
)
EOF

cat > $BASE/application/${CAP}QueryService.kt << EOF
package $FULL_PKG.application

import $FULL_PKG.domain.${CAP}Repository
import org.springframework.stereotype.Service

@Service
class ${CAP}QueryService(
    private val ${VAR_NAME}Repository: ${CAP}Repository
)
EOF

cat > $BASE/domain/${CAP}.kt << EOF
package $FULL_PKG.domain

import com.bbf.friday.bbf.back.shared.infrastructure.auditing.AuditableEntity
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table

@Entity
@Table(name = "${MODULE_NAME}")
data class ${CAP}(
    @Id
    var id: String,
) : AuditableEntity()
EOF

cat > $BASE/domain/${CAP}Repository.kt << EOF
package $FULL_PKG.domain

import org.springframework.data.domain.Page
import java.util.*

interface ${CAP}Repository {
    fun findAll(): Page<${CAP}>
    fun findById(id: String): Optional<${CAP}>
    fun save(${VAR_NAME}: ${CAP}): ${CAP}
}
EOF

cat > $BASE/infrastructure/http/${CAP}Controller.kt << EOF
package $FULL_PKG.infrastructure.http

import $FULL_PKG.application.${CAP}CommandService
import $FULL_PKG.application.${CAP}QueryService
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/${MODULE_NAME}")
class ${CAP}Controller (
    private val ${VAR_NAME}CommandService: ${CAP}CommandService,
    private val ${VAR_NAME}QueryService: ${CAP}QueryService
)
EOF

cat > $BASE/infrastructure/persistence/JPAImpl${CAP}Repository.kt << EOF
package $FULL_PKG.infrastructure.persistence

import $FULL_PKG.domain.${CAP}
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.JpaSpecificationExecutor

interface JPAImpl${CAP}Repository : JpaRepository<${CAP}, String>, JpaSpecificationExecutor<${CAP}>
EOF

cat > $BASE/infrastructure/persistence/${CAP}RepositoryImpl.kt << EOF
package $FULL_PKG.infrastructure.persistence

import $FULL_PKG.domain.${CAP}
import $FULL_PKG.domain.${CAP}Repository
import org.springframework.data.domain.Page
import org.springframework.stereotype.Service
import java.util.Optional

@Service
class ${CAP}RepositoryImpl(
    private val jpaImpl${CAP}Repository: JPAImpl${CAP}Repository
) : ${CAP}Repository {

    override fun findAll(): Page<${CAP}> {
        TODO("Not yet implemented")
    }

    override fun findById(id: String): Optional<${CAP}> {
        TODO("Not yet implemented")
    }

    override fun save(${VAR_NAME}: ${CAP}): ${CAP} {
        TODO("Not yet implemented")
    }
}
EOF

fi

echo "✅ Módulo '$MODULE_NAME' creado correctamente en:"
echo "$BASE"
