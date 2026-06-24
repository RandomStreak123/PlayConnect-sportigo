<script setup>
import logoUrl from '../assets/logo.png'
</script>

<template>
  <img :src="logoUrl" alt="PlayConnect Logo" class="pc-logo-img" />
</template>

<style scoped>
.pc-logo-img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}
</style>
