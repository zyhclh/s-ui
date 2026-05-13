<script lang="ts" setup>
import { HumanReadable } from '@/plugins/utils'
import { computed } from 'vue'

const props = defineProps({
  tilesData: <any>{},
  type: String
})

const data = computed(() => {
  const d = props.tilesData
  if (!d) return { percent: 0, text: '-' }
  switch (props.type) {
    case 'g-cpu':
      return { percent: d.cpu ?? 0, text: Math.ceil(d.cpu ?? 0) + "%" }
    case 'g-mem':
      return gaugeData(d.mem)
    case 'g-dsk':
      return gaugeData(d.dsk)
    case 'g-swp':
      return gaugeData(d.swp)
  }
  return { percent: 0, text: '-'}
})

const gaugeData = (d:any) :any => {
  if (!d || !d.total || d.total <= 0) return { percent: 0, text: '-' }
  const curr = sizeFormat(d.current ?? 0, d.total)
  const total = HumanReadable.sizeFormat(d.total,0).split(' ')
  if (curr[1] == total[1]) curr[1] = ''
  return {
    percent: Math.min(Math.ceil((d.current ?? 0)*100/d.total), 100),
    text: curr[0] + "<sup>" + (curr[1]?? ' ') + "</sup>/" +  total[0] + "<sup>" + (total[1]?? '') + "</sup>"
  }
}

const sizeFormat = (current:number, total:number) :string[] => {
  if (current > 0) return HumanReadable.sizeFormat(current, 0).split(' ')

  const totalFormat = HumanReadable.sizeFormat(total, 0).split(' ')
  return ['0', totalFormat[1] ?? '']
}

const cssTransformRotateValue = computed(() => {
  const percentage = Math.max(Math.min(data.value.percent, 100), 0)
  const percentageAsFraction = percentage / 100
  const halfPercentage = percentageAsFraction / 2

  return `${halfPercentage}turn`
})

const gaugeColor = computed(() => {
  if (data.value.percent > 90) return 'error'
  if (data.value.percent > 70) return 'warning'
  return 'info'
})
</script>

<template>
  <div class="gauge__outer">
    <div class="gauge__inner">
      <div
        class="gauge__fill" 
        :style="{ 
          transform: `rotate(${cssTransformRotateValue})`,
          background: `rgb(var(--v-theme-${gaugeColor}))`
          }">
      </div>
      <div class="gauge__cover"><span dir="ltr" v-html="data.text"></span></div>
    </div>
  </div>
</template>

<style scoped>
.gauge__outer {
  width: 100%;
  max-width: 250px;
  container-type: inline-size;
}

.gauge__inner {
  width: 100%;
  height: 0;
  padding-bottom: 50%;
  background: rgb(var(--v-theme-surface));
  position: relative;
  border-top-left-radius: 100% 200%;
  border-top-right-radius: 100% 200%;
  overflow: hidden;
}

.gauge__fill {
  position: absolute;
  top: 100%;
  left: 0;
  width: inherit;
  height: 100%;
  background: rgb(var(--v-theme-primary));
  transform-origin: center top;
  transform: rotate(0turn);
  transition: transform 0.2s ease-out;
}

.gauge__cover {
  width: 75%;
  height: 150%;
  background: rgb(var(--v-theme-background));
  position: absolute;
  top: 25%;
  left: 50%;
  transform: translateX(-50%);
  border-radius: 50%;

  /* Text */
  display: flex;
  align-items: center;
  justify-content: center;
  padding-bottom: 25%;
  box-sizing: border-box;
  font-family: 'Lexend', sans-serif;
  font-weight: bold;
  font-size: clamp(18px, 12cqi, 32px);
  line-height: 1;
}

.gauge__cover span {
  max-width: 100%;
  overflow: hidden;
  text-align: center;
  text-overflow: clip;
  white-space: nowrap;
}

:deep(sup) {
  font-size: 0.5em;
}
</style>
